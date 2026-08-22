# Notion setup

Tax Terms uses a private Notion internal integration. The integration token is
stored in the macOS Keychain and is never embedded in the application or source
code.

## Connect the Terms database

1. Open [My integrations](https://www.notion.so/my-integrations) while signed in
   to the workspace that owns the Terms database.
2. Select **New integration**, choose the workspace, and give the integration
   **Read content** and **Update content** capabilities.
3. Open the Terms database in Notion. Choose **••• → Connections** and add the
   new integration.
4. In Tax Terms, open **Admin → Notion connection**, paste the integration
   secret, and select **Save + Test + Sync**.

The app is preconfigured for data source
`6f4f4725-f14a-4cf3-be9e-91c8e54093a6`. The database already contains the
`Resources` and `Study Notes` properties required by the app.

If the integration cannot be created or added under **Connections**, a Notion
workspace owner must either create it or allow the connection. Do not paste the
token into a notes file, Git commit, issue, or chat.

## Sync ownership

- Term, Definition, Why It Matters, Example in a Sentence, Priority, Category,
  Status, Resources, and Study Notes sync in both directions.
- Local edits are tracked per field. When both copies change the same field
  before a sync, the local value is kept and Admin records a visible conflict.
- New local categories are sent to Notion as multi-select options.
- Review history, spaced-repetition timing, list definitions, UI settings, and
  field visibility stay local.
- The curated resource catalog only fills an empty Resources field; it never
  replaces a resource already stored in Notion.

