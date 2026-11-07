# Campus Notify

A mobile app for reporting broken things on campus and following what happens to them.

Students file a report with a category, a description, a location and optionally a photo. Facilities staff see those reports in a work queue and move them through submitted, in progress and resolved. Every status change is recorded with who made it and when, so a student can open their report and see exactly where it stands instead of wondering whether anyone read it.

Built with Flutter for ALU Rwanda.

## Screens

| Home | Reporting an issue | Following it |
|---|---|---|
| <img src="docs/screenshots/home.png" width="240"> | <img src="docs/screenshots/report-form.png" width="240"> | <img src="docs/screenshots/detail.png" width="240"> |

Staff see a work queue instead of their own reports, and are the only role that can move a report through its lifecycle.

| Work queue | Updating a status |
|---|---|
| <img src="docs/screenshots/staff-queue.png" width="240"> | <img src="docs/screenshots/staff-update.png" width="240"> |

## What it does

Students can:

- File a report with one of six categories, a title, a description and a campus location
- Attach a photo from the camera or the gallery
- Hide their name from other students on sensitive reports while staff still see who filed it
- Browse every report on campus, search by title, place or category, and filter by status, category and location
- Mark someone else's report as affecting them too, instead of filing a duplicate
- Withdraw their own report, but only while nobody has acted on it yet

Staff can:

- See a queue of everything unfinished, oldest first
- Move a report to in progress, resolved or closed, with a note for the reporter
- See the real name behind an anonymous report

Both get email verification on sign up, so the reporting queue stays limited to people with campus accounts.

## Running it

You need Flutter, a Firebase project and a Cloudinary account. All three are free.

```bash
git clone <this repo>
cd campus_notify
flutter pub get
```

**Firebase.** Create a project in the console. Turn on Email/Password under Authentication. Create a Firestore database in production mode. Then from the project root:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

That writes `lib/firebase_options.dart`, which is gitignored because it holds project-specific API keys.

Paste `firestore.rules` into Firestore → Rules and publish. Then create the one composite index the app needs:

- Collection: `incidents`
- Fields: `reporterId` ascending, `createdAt` descending

Without it the "My reports" tab fails with a `failed-precondition` error. The definition is in `firestore.indexes.json` if you have the Firebase CLI and would rather deploy it than click.

**Cloudinary.** Create an account, then under Settings → Upload add an upload preset. Set the signing mode to **Unsigned** and name it `campus_notify_unsigned`. Put your cloud name into `lib/core/config/cloudinary_config.dart`, or pass it at build time:

```bash
flutter run --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name
```

**Run.**

```bash
flutter run
```

Android and iOS are the supported targets. Web builds and runs, which is useful for quick iteration, but the app is meant for a phone.

## Why Cloudinary instead of Firebase Storage

Firebase Storage now requires the pay-as-you-go Blaze plan, which this project does not have. Cloudinary's free tier allows unsigned uploads straight from the client, so the architecture stays serverless and the upload path keeps the same shape: send bytes, get back an HTTPS URL, store that URL on the incident document.

`ImageRepository` is the only file that knows about Cloudinary. Swapping back to Firebase Storage means rewriting one method.

The unsigned preset is the only credential in the app. It carries no read or delete permission, so finding it in the binary gets an attacker nothing beyond the ability to upload into a folder they cannot read.

## How it is put together

```
lib/
├── app/            theme tokens and the auth gate
├── core/           constants, validators, formatters, config
├── data/           models and repositories
├── features/       one folder per feature: providers, screens, widgets
└── shared/         widgets used across features
```

Three layers, and the rule is that they only talk downwards. Widgets never import Firebase. Repositories are the only place that touches Firestore or Firebase Auth, and they translate Firebase's developer-facing error codes into sentences a student can read. Providers sit in between and hold all the state.

### State management

Riverpod, with plain `Notifier` and `AsyncNotifier` classes. No code generation.

The clearest argument for it in this project is `filteredIncidentsProvider`. There is one Firestore listener for the campus feed, and search, category filter, status filter and sort are a pure function applied to it:

```dart
final filteredIncidentsProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final filter = ref.watch(incidentFilterProvider);
  return ref.watch(allIncidentsProvider).whenData(filter.apply);
});
```

Filtering costs no extra query, no second listener and no state copied into a widget. Riverpod disposes the listener when nothing is watching it.

Everything else follows the same pattern. `appUserProvider` streams the signed-in user's profile document, so a role change made in the Firebase console reaches the running app without a restart. `AuthGate` watches the auth stream and swaps the whole tree, which is why there is no imperative navigation on sign in or sign out.

`setState` still appears, but only for things that are genuinely local: whether a password field is obscured, which tab is selected, what is typed in a text field before it is submitted.

### Data

```
users/{uid}
  fullName, email, role, programme, photoUrl, createdAt

incidents/{incidentId}
  title, description, category, status, location, locationDetail,
  photoUrl, reporterId, reporterName, isAnonymous, supporterIds,
  assignedToId, assignedToName, resolutionNote, createdAt, updatedAt

incidents/{incidentId}/statusUpdates/{updateId}
  fromStatus, toStatus, actorId, actorName, note, createdAt
```

The audit trail is a subcollection rather than an array on the parent. It grows without bound and is read on one screen only, so keeping it out of the incident document keeps list queries small.

Creating a report writes the incident and its first audit entry in one batch, so an incident can never exist without a trail. Changing a status does the same.

Timestamps use `serverTimestamp()`, so a handset with a wrong clock cannot reorder the queue.

### Access control

`firestore.rules` is the actual control. The app hides the status selector from students, but the rule is what stops a student writing a status from a REST client.

- Role is read from the user's own profile document. The update rule on `/users` refuses any write that changes `role`, so nobody can promote themselves.
- Email verification is a precondition for reading or writing anything.
- A student may edit the wording of their own report, but only while it is still submitted, and never its status or its author.
- Any verified member may touch `supporterIds` on someone else's report, and nothing else.
- Status updates are append-only. Nothing can rewrite what happened to a report.

Role is derived from the email domain at registration: addresses on the institutional domain register as staff, student addresses as students. This keeps provisioning zero-touch, and it is the weakest part of the design. Anyone who obtains a campus address gets staff powers automatically. A production deployment would invite staff explicitly and hold the role in a custom auth claim set by a Cloud Function, which needs the Blaze plan.

## Tests

```bash
flutter test
```

Eighteen unit tests covering the validators and the filter logic. Both are pure Dart with no Firebase dependency, which is deliberate: `Validators` imports nothing from Flutter, and `IncidentFilter.apply` is a pure function, so they can be tested without a widget binding, an emulator or a network.

## Known limits

- The campus feed is capped at 200 documents and filtering runs in memory. Firestore has no full-text search, and every extra `where` combined with an `orderBy` costs another composite index, so this keeps the index count at one and makes filters instant. It stops working somewhere around a few thousand live reports, at which point it needs server-side pagination and a search index.
- Role assignment follows the email domain, as described above.
- No push notifications. A student has to open the app to see that their report moved. Cloud Messaging would fix this and does not need a paid plan, but it was out of scope.
- No offline queue. Firestore caches reads, but a report composed without a connection is lost.

## Built with

Flutter, Riverpod, Firebase Authentication, Cloud Firestore, Cloudinary, Google Fonts.