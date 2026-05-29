# Package index

## Core LLM Functions

Main functions for interacting with LLM providers

- [`llm_annotate()`](https://smin95.github.io/tidychat/reference/llm_annotate.md)
  : Annotate text or images using LLMs with multiple draws
- [`llm_extract()`](https://smin95.github.io/tidychat/reference/llm_extract.md)
  : Extract multiple structured fields from text, images, PDFs, or audio
- [`llm_generate()`](https://smin95.github.io/tidychat/reference/llm_generate.md)
  : Generate structured synthetic data
- [`summarise_draws()`](https://smin95.github.io/tidychat/reference/summarise_draws.md)
  [`summarize_draws()`](https://smin95.github.io/tidychat/reference/summarise_draws.md)
  : Summarise multiple draws from LLM annotations

## Provider Selection

Choose which LLM provider to use

- [`choose_ollama()`](https://smin95.github.io/tidychat/reference/choose_ollama.md)
  : Create an Ollama chat constructor with parameter tracking
- [`choose_gemini()`](https://smin95.github.io/tidychat/reference/choose_gemini.md)
  : Create a Google Gemini chat constructor with parameter tracking
- [`choose_openai()`](https://smin95.github.io/tidychat/reference/choose_openai.md)
  : Create an OpenAI chat constructor with parameter tracking
- [`choose_anthropic()`](https://smin95.github.io/tidychat/reference/choose_anthropic.md)
  : Create an Anthropic Claude chat constructor with parameter tracking
- [`choose_groq()`](https://smin95.github.io/tidychat/reference/choose_groq.md)
  : Create a Groq chat constructor with parameter tracking
- [`choose_deepseek()`](https://smin95.github.io/tidychat/reference/choose_deepseek.md)
  : Create a DeepSeek chat constructor with parameter tracking
- [`choose_azure_openai()`](https://smin95.github.io/tidychat/reference/choose_azure_openai.md)
  : Create an Azure OpenAI chat constructor with parameter tracking
- [`choose_huggingface()`](https://smin95.github.io/tidychat/reference/choose_huggingface.md)
  : Create a Hugging Face chat constructor with parameter tracking
- [`choose_openrouter()`](https://smin95.github.io/tidychat/reference/choose_openrouter.md)
  : Create an OpenRouter chat constructor with parameter tracking

## Field Validators

Functions for defining structured data fields

- [`field_category()`](https://smin95.github.io/tidychat/reference/field_category.md)
  : Create a category field specification
- [`field_integer()`](https://smin95.github.io/tidychat/reference/field_integer.md)
  : Create an integer field specification
- [`field_number()`](https://smin95.github.io/tidychat/reference/field_number.md)
  : Create a number field specification
- [`field_text()`](https://smin95.github.io/tidychat/reference/field_text.md)
  : Create a text field specification
- [`field_boolean()`](https://smin95.github.io/tidychat/reference/field_boolean.md)
  : Create a boolean field specification
- [`field_array()`](https://smin95.github.io/tidychat/reference/field_array.md)
  : Create an array field specification
