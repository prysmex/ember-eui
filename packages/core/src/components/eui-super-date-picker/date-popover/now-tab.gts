const EuiSuperDatePickerDatePopoverNowTab = <template>
  {{! @glint-nocheck: not typesafe yet }}
  <EuiText
    class="euiDatePopoverContent__padded--large"
    @size="s"
    @color="subdued"
  >
    <p>
      <EuiI18n
        @token="euiDatePopoverContent.nowTabContent"
        @default="Setting the time to now means that on every refresh this time will be set to the time of the refresh."
        as |Token|
      >
        <Token as |value|>
          {{value}}
        </Token>
      </EuiI18n>
    </p>
    <EuiButton
      @fullWidth={{true}}
      @size="s"
      @fill={{true}}
      {{on "click" (fn @onChange "now")}}
    >
      {{#if (eq @position "start")}}
        <EuiI18n
          @token="euiDatePopoverContent.nowTabButtonStart"
          @default="Set start date and time to now"
          as |Token|
        >
          <Token as |value|>
            {{value}}
          </Token>
        </EuiI18n>
      {{else}}
        <EuiI18n
          @token="euiDatePopoverContent.nowTabButtonEnd"
          @default="Set end date and time to now"
          as |Token|
        >
          <Token as |value|>
            {{value}}
          </Token>
        </EuiI18n>
      {{/if}}
    </EuiButton>
  </EuiText>
</template>;

export default EuiSuperDatePickerDatePopoverNowTab;
