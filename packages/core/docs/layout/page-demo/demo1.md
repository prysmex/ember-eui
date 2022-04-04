# Demo

```hbs template
You are pretty much viewing a page rendered.
<EuiPage>
  <EuiPageSideBar class="mt-8">
    <EuiSideNav
      class="flex-none"
      @heading="Elastic UI"
      @isOpenMobile={{this.isOpenMobile}}
      @toggleOpenOnMobile={{set this "isOpenMobile"}}
      @items={{this.sideNavRoutes}}
      @selectedItem={{this.selectedItem}}
    />
  </EuiPageSideBar>
  <EuiPageBody>
    Hola Mundo
  </EuiPageBody>
</EuiPage>
```