import { h, onMounted, onUnmounted } from "vue";
import "./style.css";
import {DividePage} from 'vitepress-theme-api';
import { Theme } from "vitepress";
import DefaultTheme from "vitepress/theme";
import {  
  NolebaseHighlightTargetedHeading
} from '@nolebase/vitepress-plugin-highlight-targeted-heading/client'
import { enhanceAppWithTabs } from 'vitepress-plugin-tabs/client'

export default {
  extends: DefaultTheme,
  Layout: () => {
    return h(DefaultTheme.Layout, null, {
      'layout-top': () => [
        h(NolebaseHighlightTargetedHeading),
      ],
    })
  },
  enhanceApp({ app, router, siteData }) {
    // ...
    app.component("DividePage", DividePage);
    enhanceAppWithTabs(app);
  },
} satisfies Theme;