# Create an Azure OpenAI chat constructor with parameter tracking

Creates a chat constructor function for Azure OpenAI deployments.
Requires AZURE_OPENAI_API_KEY environment variable to be set.

## Usage

``` r
choose_azure_openai(
  deployment_name,
  endpoint,
  api_version = "2024-02-15-preview",
  temperature = 0.3,
  max_tokens = 2048,
  seed = NULL,
  ...
)
```

## Arguments

- deployment_name:

  Your Azure OpenAI deployment name

- endpoint:

  Azure OpenAI endpoint URL

- api_version:

  Azure API version (default: "2024-02-15-preview")

- temperature:

  Sampling temperature (0-1, default: 0.3)

- max_tokens:

  Maximum tokens to generate (default: 2048)

- seed:

  Optional random seed for reproducible outputs (if supported by
  provider)

- ...:

  Additional parameters passed to ellmer

## Value

A chat constructor function that returns a list with chat methods

## Examples

``` r
if (FALSE) { # \dontrun{
# Set API key in environment
Sys.setenv(AZURE_OPENAI_API_KEY = "your-azure-key")

# Configure Azure OpenAI
chat <- choose_azure_openai(
  deployment_name = "gpt-4-deployment",
  endpoint = "https://your-resource.openai.azure.com/"
)
} # }
```
