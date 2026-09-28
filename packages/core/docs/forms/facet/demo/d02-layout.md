---
order: 2
---

# Horizontal, loading and disabled

<EuiText>

`@layout="horizontal"` wraps the facets in rows; `@gutterSize` sets the
space between them. `@isLoading` shows a spinner instead of the count.

</EuiText>

```hbs template
<EuiFacetGroup @layout="horizontal" @gutterSize="l">
  <EuiFacetButton @quantity={{4}} @isSelected={{true}}>Kibana</EuiFacetButton>
  <EuiFacetButton @quantity={{12}}>Elasticsearch</EuiFacetButton>
  <EuiFacetButton @isLoading={{true}}>Logstash</EuiFacetButton>
  <EuiFacetButton @quantity={{0}} @isDisabled={{true}}>Beats</EuiFacetButton>
  <EuiFacetButton @quantity={{7}}>
    <:default>Jane Doe</:default>
    <:icon><EuiAvatar class="euiFacetButton__icon" @name="Jane Doe" @size="s" /></:icon>
  </EuiFacetButton>
</EuiFacetGroup>
```
