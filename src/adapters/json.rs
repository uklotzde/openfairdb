pub use ofdb_boundary::*;

use crate::core::{db::IndexedPlace, entities as e, usecases};

pub mod from_json {
    //! JSON -> Entity

    use super::*;

    // NOTE:
    // We cannot impl From<T> here, because the JSON structs
    // and the entities both are outside this crate.

    pub fn custom_link(from: CustomLink) -> usecases::CustomLinkParam {
        let CustomLink {
            url,
            title,
            description,
        } = from;
        usecases::CustomLinkParam {
            url,
            title,
            description,
        }
    }

    pub fn new_place(p: NewPlace) -> usecases::NewPlace {
        let NewPlace {
            title,
            description,
            lat,
            lng,
            street,
            zip,
            city,
            country,
            state,
            contact_name,
            email,
            telephone,
            homepage,
            opening_hours,
            founded_on,
            categories,
            tags,
            license,
            image_url,
            image_link_url,
            links,
        } = p;
        usecases::NewPlace {
            title,
            description,
            lat,
            lng,
            street,
            zip,
            city,
            country,
            state,
            contact_name,
            email,
            telephone,
            homepage,
            opening_hours,
            founded_on,
            categories,
            tags,
            license,
            image_url,
            image_link_url,
            custom_links: links.into_iter().map(custom_link).collect(),
        }
    }

    pub fn update_place(p: UpdatePlace) -> usecases::UpdatePlace {
        let UpdatePlace {
            version,
            title,
            description,
            lat,
            lng,
            street,
            zip,
            city,
            country,
            state,
            contact_name,
            email,
            telephone,
            homepage,
            opening_hours,
            founded_on,
            categories,
            tags,
            image_url,
            image_link_url,
            links,
        } = p;
        usecases::UpdatePlace {
            version,
            title,
            description,
            lat,
            lng,
            street,
            zip,
            city,
            country,
            state,
            contact_name,
            email,
            telephone,
            homepage,
            opening_hours,
            founded_on,
            categories,
            tags,
            image_url,
            image_link_url,
            custom_links: links.into_iter().map(custom_link).collect(),
        }
    }

    pub fn new_place_rating(rating: NewPlaceRating) -> usecases::NewPlaceRating {
        let NewPlaceRating {
            entry,
            title,
            value,
            context,
            comment,
            source,
            user,
        } = rating;
        usecases::NewPlaceRating {
            entry,
            title,
            value,
            context,
            comment,
            source,
            user,
        }
    }

    pub fn new_event(ev: NewEvent) -> usecases::NewEvent {
        let NewEvent {
            title,
            description,
            start,
            end,
            lat,
            lng,
            street,
            zip,
            city,
            country,
            state,
            email,
            telephone,
            homepage,
            tags,
            created_by,
            registration,
            organizer,
            image_url,
            image_link_url,
        } = ev;
        usecases::NewEvent {
            title,
            description,
            start,
            end,
            lat,
            lng,
            street,
            zip,
            city,
            country,
            state,
            email,
            telephone,
            homepage,
            tags,
            created_by,
            registration,
            organizer,
            image_url,
            image_link_url,
        }
    }

    pub fn new_user(new_user: NewUser) -> usecases::NewUser {
        let NewUser { email, password } = new_user;
        usecases::NewUser { email, password }
    }
}

pub mod to_json {
    //! Entity -> JSON

    use super::*;

    // NOTE:
    // We cannot impl From<T> here, because the JSON structs
    // and the entities both are outside this crate.

    pub fn duplicate_type(t: usecases::DuplicateType) -> DuplicateType {
        use usecases::DuplicateType as U;
        match t {
            U::SimilarChars => DuplicateType::SimilarChars,
            U::SimilarWords => DuplicateType::SimilarWords,
        }
    }
}

pub fn place_serach_result_from_indexed_place(from: IndexedPlace) -> PlaceSearchResult {
    let IndexedPlace {
        id,
        status,
        title,
        description,
        tags,
        pos,
        ratings,
        ..
    } = from;
    // The status should never be undefined! It is optional only
    // for technical reasons.
    debug_assert!(status.is_some());
    let status = status.map(Into::into);
    let (tags, categories) = e::Category::split_from_tags(tags);
    let categories = categories.into_iter().map(|c| c.id.to_string()).collect();
    let lat = pos.lat().to_deg();
    let lng = pos.lng().to_deg();
    let e::AvgRatings {
        diversity,
        fairness,
        humanity,
        renewable,
        solidarity,
        transparency,
    } = ratings;
    let total = ratings.total().into();
    let ratings = EntrySearchRatings {
        total,
        diversity: diversity.into(),
        fairness: fairness.into(),
        humanity: humanity.into(),
        renewable: renewable.into(),
        solidarity: solidarity.into(),
        transparency: transparency.into(),
    };
    PlaceSearchResult {
        id,
        status,
        lat,
        lng,
        title,
        description,
        categories,
        tags,
        ratings,
    }
}

pub fn entry_from_place_with_ratings(place: e::Place, ratings: Vec<e::Rating>) -> Entry {
    let e::Place {
        id,
        license,
        revision,
        created,
        title,
        description,
        location,
        contact,
        opening_hours,
        founded_on,
        links,
        tags,
    } = place;

    let e::Location { pos, address } = location;
    let lat = pos.lat().to_deg();
    let lng = pos.lng().to_deg();
    let e::Address {
        street,
        zip,
        city,
        country,
        state,
    } = address.unwrap_or_default();

    let e::Contact {
        name: contact_name,
        email,
        phone: telephone,
    } = contact.unwrap_or_default();

    let (homepage_url, image_url, image_link_url, custom_links) = links
        .map(
            |e::Links {
                 homepage,
                 image,
                 image_href,
                 custom,
             }| (homepage, image, image_href, custom),
        )
        .unwrap_or_default();

    let (tags, categories) = e::Category::split_from_tags(tags);

    Entry {
        id: id.into(),
        created: created.at.as_secs(),
        version: revision.into(),
        title,
        description,
        lat,
        lng,
        street,
        zip,
        city,
        country,
        state,
        contact_name,
        email: email.map(Into::into),
        telephone,
        homepage: homepage_url.map(Into::into),
        opening_hours: opening_hours.map(Into::into),
        founded_on: founded_on.map(Into::into),
        categories: categories.into_iter().map(|c| c.id.to_string()).collect(),
        tags,
        ratings: ratings.into_iter().map(|r| r.id.to_string()).collect(),
        license: Some(license),
        image_url: image_url.map(Into::into),
        image_link_url: image_link_url.map(Into::into),
        custom_links: custom_links.into_iter().map(Into::into).collect(),
    }
}
