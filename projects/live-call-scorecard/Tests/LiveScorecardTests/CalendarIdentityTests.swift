import Foundation
import XCTest
@testable import LiveScorecard

final class CalendarIdentityTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testBusinessEmailUsesOrganizationDomainIdentity() {
        let event = makeEvent(
            title: "Northwind discovery",
            attendees: [attendee("alex@northwindtax.com", name: "Alex Owner")]
        )

        let result = CalendarProspectResolver.resolve(events: [event], at: now)

        guard case let .matched(match) = result else {
            return XCTFail("Expected a calendar identity match")
        }
        XCTAssertEqual(match.eventTitle, "Northwind discovery")
        XCTAssertEqual(match.identity.key, "email:alex@northwindtax.com")
        XCTAssertEqual(match.identity.displayName, "Alex Owner")
        XCTAssertEqual(match.identity.primaryEmail, "alex@northwindtax.com")
        XCTAssertEqual(match.identity.organizationDomain, "northwindtax.com")
        XCTAssertEqual(match.identity.inferredOrganizationName, "Northwind Tax")
    }

    func testPersonalEmailUsesExactAddressInsteadOfGroupingAllGmailProspects() {
        let event = makeEvent(
            title: "Taylor follow-up",
            attendees: [attendee("taylor.owner@gmail.com", name: "Taylor Owner")]
        )

        let result = CalendarProspectResolver.resolve(events: [event], at: now)

        guard case let .matched(match) = result else {
            return XCTFail("Expected a calendar identity match")
        }
        XCTAssertEqual(match.identity.key, "email:taylor.owner@gmail.com")
        XCTAssertEqual(match.identity.displayName, "Taylor Owner")
        XCTAssertNil(match.identity.organizationDomain)
    }

    func testInternalAttendeeIsIgnored() {
        let event = makeEvent(
            title: "Internal review",
            attendees: [attendee("ross@cranston.ai", name: "Ross")]
        )

        XCTAssertEqual(
            CalendarProspectResolver.resolve(events: [event], at: now),
            .unavailable("ACTIVE EVENT HAS NO UNIQUE EXTERNAL ATTENDEE")
        )
    }

    func testMultipleSimultaneousProspectsAreRejectedRatherThanGuessed() {
        let first = makeEvent(
            identifier: "one",
            title: "First prospect",
            attendees: [attendee("a@firsttax.com")]
        )
        let second = makeEvent(
            identifier: "two",
            title: "Second prospect",
            attendees: [attendee("b@secondtax.com")]
        )

        XCTAssertEqual(
            CalendarProspectResolver.resolve(events: [first, second], at: now),
            .unavailable("MULTIPLE ACTIVE PROSPECT EVENTS")
        )
    }

    func testActiveMeetingWinsOverNearbyFutureMeeting() {
        let active = makeEvent(
            identifier: "active",
            title: "Active",
            attendees: [attendee("owner@activefirm.com")]
        )
        let future = CalendarEventSnapshot(
            identifier: "future",
            title: "Future",
            startDate: now.addingTimeInterval(8 * 60),
            endDate: now.addingTimeInterval(60 * 60),
            isAllDay: false,
            isCanceled: false,
            hasGoogleMeet: true,
            organizer: nil,
            attendees: [attendee("owner@futurefirm.com")]
        )

        let result = CalendarProspectResolver.resolve(events: [future, active], at: now)
        guard case let .matched(match) = result else {
            return XCTFail("Expected a calendar identity match")
        }
        XCTAssertEqual(match.eventIdentifier, "active")
    }

    func testManualEmailIdentityUsesExactAddressAndDerivesEditableMetadata() throws {
        let identity = try XCTUnwrap(CalendarProspectResolver.identity(
            email: " Carry.Jones@greenfieldtax.com ",
            displayName: "Carry Jones"
        ))

        XCTAssertEqual(identity.key, "email:carry.jones@greenfieldtax.com")
        XCTAssertEqual(identity.displayName, "Carry Jones")
        XCTAssertEqual(identity.organizationDomain, "greenfieldtax.com")
        XCTAssertEqual(identity.inferredOrganizationName, "Greenfield Tax")
    }

    private func makeEvent(
        identifier: String = "event",
        title: String,
        attendees: [CalendarAttendeeSnapshot]
    ) -> CalendarEventSnapshot {
        CalendarEventSnapshot(
            identifier: identifier,
            title: title,
            startDate: now.addingTimeInterval(-15 * 60),
            endDate: now.addingTimeInterval(45 * 60),
            isAllDay: false,
            isCanceled: false,
            hasGoogleMeet: true,
            organizer: attendee("ross@cranston.ai", name: "Ross", isCurrentUser: true),
            attendees: attendees
        )
    }

    private func attendee(
        _ email: String,
        name: String? = nil,
        isCurrentUser: Bool = false
    ) -> CalendarAttendeeSnapshot {
        CalendarAttendeeSnapshot(
            name: name,
            email: email,
            isCurrentUser: isCurrentUser,
            isDeclined: false,
            isPerson: true
        )
    }
}
