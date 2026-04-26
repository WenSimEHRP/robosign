# Robosign

## Architecture

Robosign is a simple tool for generating station signs. It does the following:

- Take a Typst template.
- Tuck some text into it (by passing in some JSON).
- Compile it to an SVG.
- Render the SVG and display it on the page.
- Provide options to download the SVG, PNG, or PDF

Rendering is done client-side using typst.ts. This site should feature a minimal amount of client-side JS, and no
server-side code at all.

## UI Layout

The UI should be simple and straightforward. Specifically, there are these requirements:

- Each typst template should correspond to a "sign type" that the user can select from the left-hand sidebar.
- The user should be routed to a different page for each sign type; the URL should reflect the type (e.g. /signs/line).
- The export button should be at the very top of the page, and should be visible at all times (i.e., sticky).

## i18n

The site uses FLUENT .ftl files for internationalization. Each sign type should have its own .ftl file, and there should
be a default .ftl file for any strings that are shared across sign types. The .ftl files should be stored in a directory
called "locales", and should be named according to the language code (e.g. en.ftl, fr.ftl, etc.). The site should
automatically detect the user's language and load the appropriate .ftl file. If the user's language is not supported, it
should fall back to English.

## Typst templates

Each sign type would have its corresponding Typst template.
