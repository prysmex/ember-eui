---
order: 4
---

# Float images within text

<EuiText>
<p>When using <EuiCode @language="text">EuiImage</EuiCode> within <EuiCode @language="text">EuiText</EuiCode> it is often useful to apply floats. Almost always you'll want to pair the <EuiCode @language="text">float</EuiCode> prop usage, with a <EuiCode @language="text">margin</EuiCode> prop usage to give space around your image. Margins, when used in combo with floats, will adjust depending upon the position of the float.</p>
</EuiText>

```hbs template
<EuiText>
  <EuiImage
    @size='l'
    @float='right'
    @margin='l'
    @hasShadow={{true}}
    @caption='Random nature image'
    @allowFullScreen={{true}}
    @alt='Random nature image'
    @url='https://picsum.photos/800/500'
  />
  <p>Eius et sunt. Nisi neque quis. Quae expedita non iure odit qui consequatur
    beatae. Quos laboriosam voluptas eaque aut nostrum blanditiis sint aut enim.
    Quos alias aliquam modi laborum. Mollitia qui minima suscipit voluptatem
    nesciunt labore vero qui quia. Voluptatem quibusdam deleniti laudantium
    totam laborum architecto ad eligendi consequatur. Iusto architecto debitis
    sit aspernatur consectetur corrupti sit excepturi quasi. Vero error facilis
    ea eum molestias sunt aliquam rerum libero. Eos aut aut commodi optio quod
    repellat. Dolorem exercitationem placeat a dicta. Maiores qui quia ratione
    quasi. Facilis laboriosam est magni tempore qui pariatur quia.
  </p>
  <p>Qui minus quo. Aut est rem totam. Et aliquid vitae ad aspernatur blanditiis
    illo nam voluptatem numquam. Voluptatem ducimus iure voluptas voluptates est
    quibusdam porro aliquam accusantium. Accusantium repellendus consequatur
    eveniet omnis autem. Et deleniti consequatur aliquam et quis nemo rem
    excepturi modi. Delectus beatae magni quasi dolorem fugiat. Et qui debitis
    in et. Qui id aut maxime consequatur. Optio et ut quam sint excepturi.
    Tenetur cum maiores accusamus ea. Ad sit ut aliquam rerum eius culpa et.</p>
  <p>Velit doloribus expedita eos voluptas est debitis adipisci laboriosam
    consequuntur. Officia repellat aut voluptas sunt. Ipsam dignissimos natus
    labore reiciendis est numquam quia soluta rerum. Nisi modi est aliquid.
    Animi mollitia et fugit enim et. Voluptatem laudantium laudantium corrupti
    sit explicabo itaque esse omnis voluptate. Nemo dolorum ut. Voluptatibus eum
    voluptatem sit laborum velit cupiditate repudiandae id. Atque neque sed
    corporis aut quia error voluptates cupiditate aut. Ut quam aperiam earum
    dolor est dicta tempore voluptatem sint. Beatae assumenda nemo aperiam
    nesciunt. Quaerat id voluptas commodi.</p>
  <EuiImage
    @size='l'
    @float='left'
    @margin='l'
    @hasShadow={{true}}
    @allowFullScreen={{true}}
    @caption='Another random image'
    @alt='Random nature image'
    @url='https://picsum.photos/300/300'
  />
  <p>Earum ea voluptatibus reprehenderit dolorum non et aperiam eum non.
    Expedita doloribus itaque. Consectetur non et aut sit quis inventore eos et.
    Aut fuga veniam magnam excepturi nihil. Enim ut et. Dolores sint iste minima
    itaque non et atque magnam iure. Odio perspiciatis qui cumque autem autem.
    Ut nam beatae voluptatem expedita incidunt vel ea enim. Qui unde dolores
    earum eos. Et repudiandae aliquid quia rerum ducimus doloremque. Consectetur
    ut perferendis totam. Veniam in suscipit omnis. Ut est quidem et iste
    voluptatem officia ad. Officia in perferendis necessitatibus.</p>
  <p>Est ut ut iure sunt ab et. Iste possimus necessitatibus quia totam dolorem
    distinctio harum totam et. Quaerat in totam non officiis ut. Provident
    fugiat repellendus autem libero harum ducimus doloribus autem reiciendis.
    Odio qui nesciunt consequatur et illum quia. Non dicta et voluptatibus rerum
    dolor. Illum consequatur deleniti dolor dignissimos quod rerum. Ut quidem
    eos sapiente rerum numquam laudantium. Nostrum sunt quia quis est sit.
    Ratione sint error. Alias animi ullam unde magnam repellendus omnis et quia
    dolorem. Voluptas quidem laudantium totam quisquam in reiciendis officiis.
    Et suscipit doloribus earum quis nihil voluptatem provident aut vero.
    Accusantium ducimus voluptatem ad aperiam ut consequatur. Ut dicta
    consequatur. Dignissimos ipsum accusamus quos provident consequatur. Sequi
    temporibus quisquam voluptates eum eos consectetur et.</p>
</EuiText>
```
