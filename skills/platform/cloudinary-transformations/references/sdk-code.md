# Generating SDK Code

This skill describes transformations in URL syntax, but if the user is working in code, give them SDK code rather than a hand-built URL string. Each SDK has its own names and syntax for the same transformation, so **don't guess SDK syntax from the URL parameters**. Get it from the Transformation Reference.

## 1. Work out the user's SDK

Check the project's dependency files for a Cloudinary package, and use the matching code-block tag in step 3. The rows are ordered most specific first. For example, a Next.js project also depends on `cloudinary`, so use the first row that matches:

| Dependency found | File | Code-block tag |
|---|---|---|
| `next-cloudinary` | `package.json` | Use the cloudinary-next skill if it's installed. Otherwise, see the Next.js note below this table. |
| `@cloudinary/react` | `package.json` | `react` (use the cloudinary-react skill too, if it's installed) |
| `@cloudinary/vue` | `package.json` | `vue` |
| `@cloudinary/ng` | `package.json` | `angular` |
| `cloudinary-react-native` | `package.json` | `react_native` |
| `@cloudinary/url-gen` only | `package.json` | `js` |
| `cloudinary` (server-side Node.js) | `package.json` | `nodejs` |
| `cloudinary-jquery` | `package.json` | `jquery` |
| `cloudinary` | `requirements.txt`, `pyproject.toml` | `python` |
| `cloudinary/cloudinary_php` | `composer.json` | `php` |
| `cloudinary` | `Gemfile` | `ruby` |
| `com.cloudinary:cloudinary-http*` | `pom.xml`, `build.gradle` | `java` |
| `com.cloudinary:cloudinary-android*` | `build.gradle` | `android` |
| `com.cloudinary:kotlin-url-gen` | `build.gradle(.kts)` | `kotlin` |
| `CloudinaryDotNet` | `*.csproj` | `csharp` |
| `cloudinary_flutter` | `pubspec.yaml` | `flutter` |
| `cloudinary_url_gen` only | `pubspec.yaml` | `dart` |
| `Cloudinary` | `Podfile`, `Package.swift` | `swift` |

**Next.js without the cloudinary-next skill:** The Transformation Reference has no Next.js examples, so don't guess `CldImage` props. Do step 2, then pass the whole transformation string to `CldImage` or `getCldImageUrl` through `rawTransformations`, for example `rawTransformations={['c_fill,g_auto,h_300,w_400/f_auto/q_auto']}`. Keep every transformation in `rawTransformations`. Don't also set the equivalent props (such as `format` or `quality`), because mixing the two produces duplicate parameters. Suggest that the user install the cloudinary-next skill for more idiomatic code.

If there's no dependency file, go by the language of the file the user is editing. If it's still unclear, or the project uses more than one SDK (for example, a Node.js backend and a React frontend), ask which one the code is for.

## 2. Design the transformation in URL syntax

Use SKILL.md to build and validate the transformation string (for example, `c_fill,g_auto,h_300,w_400/f_auto/q_auto`). The URL is the canonical form. Get it right first, then translate it.

## 3. Get the SDK code from the Transformation Reference

1. Open the [Transformation Reference](https://cloudinary.com/documentation/transformation_reference.md?install_source=skillspack&referrer=trans-skill) index and find the page for each parameter in the transformation. For example, `c_fill` is at [transformation_reference_c_crop_resize_fill.md](https://cloudinary.com/documentation/transformation_reference_c_crop_resize_fill.md?install_source=skillspack&referrer=trans-skill).
2. Each example on a parameter page is followed by code blocks tagged with the SDK name (`nodejs`, `react`, `python`, `php`, etc.). Read the block for the user's SDK, choosing the example closest to what you need.
3. Combine the snippets into one expression, following the chaining pattern the snippets show. For example, `@cloudinary/url-gen` chains action methods (`.resize(...).delivery(...)`). The Node.js, Python and Ruby SDKs take an array of transformation objects (`transformation: [{...}, {...}]`), one per URL component.
4. Replace the example public IDs (such as `docs/camera-640.jpg`) and values with the user's.
5. Add the imports. Some snippets include per-transformation imports (for example, `import { fill } from "@cloudinary/url-gen/actions/resize"` or PHP's `use Cloudinary\Transformation\Resize;`). Copy them and merge duplicates. The snippets never show the SDK's base import or setup (such as `CloudinaryImage`, `require('cloudinary').v2`, or the Kotlin and Dart SDK imports). Reuse the one already in the user's code. If there isn't one, get it from that SDK's docs page rather than guessing.

**Watch out for:**
- **Tag vs URL:** Many snippets generate an HTML tag (`cloudinary.image()` in Node.js, `.image()` in Python, `cl_image_tag` in Ruby). If the user needs only the URL, use the SDK's URL method instead (`cloudinary.url()`, `.build_url()`, `cl_image_path`).
- **SDK version:** The examples use each SDK's current major version. If the user's code uses an older API style (for example, `cloudinary-core` instead of `@cloudinary/url-gen`), match their existing code. Tell them the reference examples target a newer version.
- **No example for a parameter:** Don't invent method names. Use the SDK's raw transformation option instead (`addTransformation("...")` in `@cloudinary/url-gen`, `raw_transformation` in the Node.js, Python and Ruby SDKs), and tell the user that's what you did.

After writing the code, show the delivery URL it generates. The user can check it against the transformation string from step 2.
