# Demo

```hbs template
<div class="euiFlexGrid euiFlexGrid--halves euiFlexGrid--responsive euiFlexGrid--gutterLarge">
  <div class="euiFlexItem">
    <EuiText @size="s">
      Clickable with href
    </EuiText>
    <EuiCard
      @title="Darth Vader"
      @titleSize="s"
      @titleElement="h3"
      @description="Dark Lord of the Sith"
      @layout="vertical"
      @paddingSize="l"
      @href="https://starwars.fandom.com/wiki/Anakin_Skywalker"
      @image="https://1.bp.blogspot.com/-nMzqcqU8SwE/W4l4yJdZUVI/AAAAAAAAALQ/qUNHiJg-OwEccNcDzOMLdRhEOvn7sgI2gCLcBGAs/s1600/Darth%2BVader%2B-%2BStar%2BWars%2B-%2BBlack%2BWallpaper%2BBackground.jpg" as |Card|
    >
      <Card.body>
        <EuiText @size="xs" @textAlign="left" @grow={{true}}>
          <p>
            Darth Vader's true name is Anakin Skywalker.
            <br />
            The One chosen by the force itself to bring balance to the galaxy.
                The potentially most powerful force user to ever come to existence,
                only to be seduced by the dark side; bringing chaos and destruction across the galaxy.
          </p>
        </EuiText>
      </Card.body>
      <Card.footer>
        <EuiBadgeGroup @gutterSize="m">
          <EuiBadge>
            Dark Side
          </EuiBadge>
          <EuiBadge>
            Sith Lord
          </EuiBadge>
          <EuiBadge>
            Force
          </EuiBadge>
          <EuiBadge>
            Empire
          </EuiBadge>
        </EuiBadgeGroup>
      </Card.footer>
    </EuiCard>
  </div>
  <div class="euiFlexItem">
    <EuiText @size="s">
      Basic
    </EuiText>
    <EuiCard
      @title="Darth Sidious"
      @titleSize="s"
      @titleElement="h3"
      @description="Galactic Emperor"
      @layout="vertical"
      @paddingSize="l"
      @image="https://i.pinimg.com/originals/ab/eb/f4/abebf495862d9b822d0b368879d1ea00.jpg" as |Card|
    >
      <Card.body>
        <EuiText @size="xs" @textAlign="left" @grow={{true}}>
          <p>
            Sidious's real name is Sheev Palpatine. He was a former member of the Galactic Senat annd secretly the Dark Lord of the Sith.
                After the Jedi genocide, he became the self-titled Emperor of the Galaxy.
            <br />
            "There is only one plan—one great design which shall govern the universe—mine."
          </p>
        </EuiText>
      </Card.body>
      <Card.footer>
        <EuiBadgeGroup>
          <EuiBadge>
            Dark Side
          </EuiBadge>
          <EuiBadge>
            Sith Lord
          </EuiBadge>
          <EuiBadge>
            Force
          </EuiBadge>
          <EuiBadge>
            Empire
          </EuiBadge>
        </EuiBadgeGroup>
      </Card.footer>
    </EuiCard>
  </div>
  <div class="euiFlexItem">
    <EuiText @size="s">
      Disabled
    </EuiText>
    <EuiCard
      @title="Darth Nihilus"
      @titleSize="s"
      @titleElement="h3"
      @description="Lord of Hunger"
      @layout="vertical"
      @isDisabled={{true}}
      @paddingSize="l"
      @href="https://starwars.fandom.com/"
      @image="https://cdn.hipwallpaper.com/i/29/87/pyJ0Pi.jpg" as |Card|
    >
      <Card.body>
        <EuiText @size="xs" @textAlign="left" @grow={{true}}>
          <p>
            Considered to be an actual wound in the force, Nihilus experiences a never-ending hunger
            <br />
            for force energy. Able to strip entire planets of their life-force energy for himself,
            <br />
            He became to be considered as arguably one of the most powerful Sith Lords to have ever existed.
          </p>
        </EuiText>
      </Card.body>
      <Card.footer>
        <EuiBadgeGroup>
          <EuiBadge>
            Sith Lord
          </EuiBadge>
          <EuiBadge>
            Old Republic
          </EuiBadge>
          <EuiBadge>
            Jedi Civil War
          </EuiBadge>
        </EuiBadgeGroup>
      </Card.footer>
    </EuiCard>
  </div>
  <div class="euiFlexItem">
    <EuiText @size="s">
      Beta Badge
    </EuiText>
    <EuiSpacer @size="m" />
    <EuiCard
      @title="Millenium Falcon"
      @titleSize="s"
      @titleElement="h3"
      @description="From Smuggler to Warship"
      @layout="vertical"
      @paddingSize="l"
      @betaBadgeLabel="Alpha"
      @image="https://cdn.wallpapersafari.com/8/67/A3xeaM.jpg" as |Card|
    >
      <Card.body>
        <EuiText @size="xs" @textAlign="left" @grow={{true}}>
          <p>
            By far the most iconic ship in the galaxy.
            <br />
            Commandeered by the its trusty crew of smugglers turned warriors: Han Solo and Chewbacca.
          </p>
        </EuiText>
      </Card.body>
      <Card.footer>
        <div class="euiFlexGroup euiFlexGroup--justifyContentSpaceAround">
          <EuiButton class="euiFlexItem euiFlexItem--flexGrowZero" {{on "click" this.punchIt}} @fill={{true}}>
              Try it!
          </EuiButton>
        </div>
      </Card.footer>
    </EuiCard>
  </div>
  <div class="euiFlexItem">
    <EuiText @size="s">
      Plain Card
    </EuiText>
    <EuiSpacer @size="m" />
    <EuiCard
      @title="X Wing"
      @titleSize="s"
      @titleElement="h3"
      @description="Republic Signature"
      @layout="vertical"
      @paddingSize="l"
      @display="plain"
      @image="https://i.pinimg.com/originals/09/60/ab/0960ab6bb8a217da7362d88ff7b3a0af.jpg" as |Card|
    >
      <Card.body>
        <EuiText @size="xs" @textAlign="left" @grow={{true}}>
          <p>
            The fighter of the republic.
            <br />
            Maneuvered by the galaxy's most talented pilots,
                this is the primary starfighter of the Rebellion and New Republic.
          </p>
        </EuiText>
      </Card.body>
      <Card.footer>
        <EuiBadgeGroup>
          <EuiBadge>
            Republic
          </EuiBadge>
          <EuiBadge>
            xwing
          </EuiBadge>
          <EuiBadge>
            starfighter
          </EuiBadge>
        </EuiBadgeGroup>
      </Card.footer>
    </EuiCard>
  </div>
  <div class="euiFlexItem">
    <EuiText @size="s">
      Plain Card with Beta Badge and OnClick
    </EuiText>
    <EuiSpacer @size="m" />
    <EuiCard
      @title="Slave I"
      @titleSize="s"
      @titleElement="h3"
      @description="Fierce"
      @layout="vertical"
      @paddingSize="l"
      @display="plain"
      @betaBadgeLabel="Beta"
      @image="https://i.imgur.com/LWzoQ0S.png"
      @onClick={{this.punchIt}} as |Card|
    >
      <Card.body>
        <EuiText @size="xs" @textAlign="left" @grow={{true}}>
          <p>
            The powerhouse of the most feared bounty hunter across the galaxy: Boba Fett.
            <br />
            The Slave I is slave to none but the bounty hunter himself.
                If you see it coming, you know he is out for you, and there is no stopping him.
          </p>
        </EuiText>
      </Card.body>
      <Card.footer>
        <EuiBadgeGroup>
          <EuiBadge>
            Mandalore
          </EuiBadge>
          <EuiBadge>
            Fett
          </EuiBadge>
          <EuiBadge>
            bounty
          </EuiBadge>
        </EuiBadgeGroup>
      </Card.footer>
    </EuiCard>
  </div>
</div>
<EuiSpacer @size="l" />
<EuiTitle @size="m">
  Warring Factions
</EuiTitle>
<EuiSpacer @size="s" />
<div
  class="euiFlexGroup euiFlexGroup--directionRow euiFlexGroup--responsive euiFlexGroup--gutterLarge"
>
  <div class="euiFlexItem">
    <EuiText @size="s">
      Card with horizontal Layout and BetaBadge
    </EuiText>
    <EuiSpacer @size="m" />
    <EuiCard
      @layout="horizontal"
      @icon="https://vignette.wikia.nocookie.net/starwarsofthecaribbean/images/0/0d/NR_Seal_red.svg.png/revision/latest/scale-to-width-down/340?cb=20171216141737"
      @iconSize="xxl"
      @title="Galatic Republic"
      @titleSize="s"
      @titleElement="h3"
      @description="The Rebellion"
      @betaBadgeLabel="A New Hope"
    >
      <EuiText @size="xs" @textAlign="left" @grow={{true}}>
        <p>
          Firstly known as the Rebellion, was a group of freedom fighters
              that overthrew the Galactic Empire, and established the New Republic.
        </p>
      </EuiText>
    </EuiCard>
  </div>
  <div class="euiFlexItem">
    <EuiText @size="s">
      Plain Card horizontal layout
    </EuiText>
    <EuiSpacer @size="m" />
    <EuiCard
      @layout="horizontal"
      @display="plain"
      @icon="https://i.pinimg.com/originals/10/54/a4/1054a48bf3914f0fae0f974e2e021af3.png"
      @iconSize="xxl"
      @title="Galatic Empire"
      @titleSize="s"
      @titleElement="h3"
      @description="Reign of the Sith"
      @href="https://starwars.fandom.com/wiki/Galactic_Empire"
    >
      <EuiText @size="xs" @textAlign="left" @grow={{true}}>
        <p>
          The Galactic Empire was the reign of Darth Sidious, the Dark Lord of the Sith.
        </p>
        <p>
          Click on the card for more info!
        </p>
      </EuiText>
    </EuiCard>
  </div>
</div>
<EuiSpacer @size="xl" />
<EuiTitle @size="m">
  Selectable
</EuiTitle>
<EuiSpacer @size="s" />
<div
  class="euiFlexGroup euiFlexGroup--directionRow euiFlexGroup--responsive euiFlexGroup--gutterLarge"
>
  <div class="euiFlexItem">
    <EuiCard
      @title="E-11 Blaster Rifle"
      @titleSize="s"
      @titleElement="h3"
      @description="Manufactured by BlasTech Industries"
      @image="https://vignette.wikia.nocookie.net/starwars/images/2/20/E-11_blaster_rifle_DICE.png/revision/latest/scale-to-width-down/500?cb=20151106030234"
      @selectable={{hash
        color="primary"
        onClick=(fn this.selectToggle "cardOneSelected")
        isSelected=this.cardOneSelected
      }}
    />
  </div>
  <div class="euiFlexItem">
    <EuiCard
      @title="A280 Blaster Rifle"
      @titleSize="s"
      @titleElement="h3"
      @description="Manufactured by BlasTech Industries"
      @image="https://vignette.wikia.nocookie.net/starwars/images/c/c1/A280_blaster_rifle.jpg/revision/latest/scale-to-width-down/499?cb=20061203115750"
      @selectable={{hash
        onClick=(fn this.selectToggle "cardTwoSelected")
        isSelected=this.cardTwoSelected
      }}
    />
  </div>
  <div class="euiFlexItem">
    <EuiCard
      @title="E-10 Blaster Rifle"
      @titleSize="s"
      @titleElement="h3"
      @description="Manufactured by BlasTech Industries"
      @image="https://vignette.wikia.nocookie.net/starwars/images/6/6f/E-10.png/revision/latest/scale-to-width-down/500?cb=20181125220049"
      @selectable={{hash
        onClick=(fn this.selectToggle "cardThreeSelected")
        isSelected=this.cardThreeSelected
      }}
    />
  </div>
  <div class="euiFlexItem">
    <EuiCard
      @title="E-5C Heavy Blaster Rifle"
      @titleSize="s"
      @titleElement="h3"
      @description="Manufactured by BlasTech Industries"
      @image="https://vignette.wikia.nocookie.net/starwars/images/b/ba/E-5C_BF2.png/revision/latest/scale-to-width-down/499?cb=20180310060911"
      @selectable={{hash
        onClick=(fn this.selectToggle "cardFourSelected")
        isSelected=this.cardFourSelected
        isDisabled=this.weaponLocked
      }}
    />
  </div>
</div>
```

```js component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoCardComponent extends Component {
  @tracked cardOneSelected = false;
  @tracked cardTwoSelected = false;
  @tracked cardThreeSelected = false;
  @tracked cardFourSelected = false;

  @tracked weaponLocked = true;

  @action
  punchIt() {
    alert('You punched into hyperspacer!');
  }

  @action
  selectToggle(card, event) {
    this[card] = !this[card];
    event.stopPropagation();
  }
}
```
