# Spectrum AI Usage Guidelines
##### v1.0.0 | Copyright (c) Liam Sherwin | June 2026

---

## 0.0 Definitions

- **I, us, we:** The Spectrum development team, including but not limited to the lead developer: Liam Sherwin
- **You:** Any person contributing to the development of any product, service, repository, or supporting resource that is part of the Spectrum organisation, whether a member of the Spectrum organisation or an external contributor
- **AI:** Any kind of artificial intelligence, including but not limited to: Generative AI, or LLMs
- **Product:** Any product, service, repository, documentation site, supporting tool or resource that is part of the Spectrum organisation
- **Contributor:** Any person submitting code, text, assets, or other changes to any product. Including participation in discussionsor issue reporting.
- **Contribution:** Any code, text, asset, or other change submitted by a contributor to any product, via a pull request or direct commit
- **Spectrum organisation:** The Spectrum GitHub organisation, found at github.com/SpectrumPro, and all repositories, products, and resources contained within it

---

## 1.0 Preamble

This guideline document outlines the usage of AI tools in the development of products in the Spectrum organisation.

### 1.1 What this applies to

Any contribution to any product or service that is part of the Spectrum organisation, code or otherwise.

**Example**: *You are contributing code, documentation or assets for the purpose of product development.*

### 1.2 What this DOES NOT apply to

Anyone using a Spectrum product, or creating work with one.

**Example**: *You are including a Spectrum product's output in your personal AI workflow.*

---

## 2.0 Usage of AI generated code

- **2.0.1**: Prompting AI to implement a whole feature or fix is NOT allowed.

- **2.0.2**: Contributions where the majority of the code is AI generated, without any human editing, are NOT allowed.

- **2.0.3**: Using AI for repetitive tasks IS allowed. Repetitive tasks are defined as, low-complexity code, or patterns such as getters, setters, or serialisation and deserialisation of variables.

- **2.0.4**: Using AI for assistance in creating part of a contribution IS allowed HOWEVER, the outputted code must be fully understood by the contributor before it is submitted.

- **2.0.5**: AI assisted autocomplete is allowed, as long as it still follows all criteria in section 2.0.

### 2.1 AI assisted debugging

The use of AI for debugging is discouraged, as it may encourage sole reliance on AI for error detection. If AI is used during debugging, any resulting code changes or recommendations must comply with section 2.0, and any resulting documentation or text changes must comply with section 4.0.


### 2.2 Examples
- **Allowed**: *Using AI to create a conditional statement for a logic flow.*
- **Allowed**: *Using AI to create a constructor method based on local variables.*
- **Not Allowed**: *Prompting Claude code to "Implement x feature" and contributing the resulting changes.*

---

## 3.0 Usage of generative AI

Any usage of generative AI for creating images, videos, or other assets that are not purely text based is NOT allowed. For any assets that are text based, see section 2.0 or 4.0.

### 3.1 Examples
- **Allowed**: *Designing icons manually in Inkscape.*
- **Not Allowed**: *Generating icons with AI.*

---

## 4.0 Usage of AI for documentation and other non-code text

- **4.0.1**: Using AI to generate any kind of documentation, or any kind of non-code text is NOT allowed.

- **4.0.2**: Using AI to spell check and improve the readability and accessibility of text is allowed, as long as the output is not used as-is. It must be modified to match the preferred writing style of the author, and must not present as AI generated.

- **4.0.3**: Contributions originally written in another language and translated to English using AI are permitted, provided this is disclosed. 

### 4.1 Examples
**Allowed**: *Writing documentation by hand, then asking AI to spell check improve the grammar.*
**Not Allowed**: *Using AI to generate a README and commiting the direct output*

---

## 5.0 Commit messages and pull request descriptions

Commit messages and pull request descriptions must be human written, ideally by the author of the changes wherever possible. AI may be used to proofread or suggest improvements, provided the result complies with section 4.0.

### 5.1 Examples
**Not Allowed**: *Feeding AI a git diff and getting it to create a PR description*

---

## 6.0 AI usage disclosure

Any contributor outside of the Spectrum GitHub organisation submitting a pull request must declare all AI tool usage in their submission. This includes but is not limited to: code generation, debugging assistance, documentation generation, spell checking, translation, and AI assisted autocomplete.

If the declaration is omitted by mistake, the contributor will be asked to update their pull request. If the omission is deemed deliberate, the contributor may be restricted from submitting future contributions at the discretion of the Spectrum development team.

---

## 7.0 Scope and exemptions

These guidelines apply to all code, text, and assets committed or submitted by any Spectrum developer or contributor. The Spectrum development team reserves the right to grant exemptions or impose additional restrictions at any time without notice.
