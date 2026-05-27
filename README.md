<div style="margin-top: 60px;"></div>

**tidychat** is an R package designed for **interactive LLM-powered annotation and structured data extraction**. It provides a unified interface for working with multiple LLM providers including Ollama, Gemini, OpenAI, Anthropic, Groq, DeepSeek, and Azure OpenAI.

### Why use tidychat for LLM Workflows?
* **Unified Provider Interface**: Switch between LLM providers (Ollama, Gemini, OpenAI, Anthropic, Groq, DeepSeek, Azure) with a consistent API.
* **Structured Data Extraction**: Extract categorized, numeric, or text-based fields from unstructured text using field validators.
* **Batch Annotation**: Annotate large text collections with flexible field definitions and progress tracking.
* **Reproducible Workflows**: Define extraction schemas once and apply them consistently across datasets.

---

### Documentation & Examples

For detailed guides on annotation workflows and provider configuration, visit the official documentation:
👉 **[tidychat Documentation Website](https://smin95.github.io/tidychat/)**

---

### Installation using RStudio

Install the development version of **tidychat** from GitHub:

```r
# Install remotes if not already installed
# install.packages("remotes")

remotes::install_github("smin95/tidychat")
```
