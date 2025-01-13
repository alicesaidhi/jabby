---
# https://vitepress.dev/reference/default-theme-home-page
layout: home
pageClass: home
next:
  text: 'Introduction'
  link: '/tut/crash-course/1-introduction'

hero:
  name: "jabby"
  text: ECS debugger and tooling for JECS
  tagline: Powerful library for debugger tooling for ECS
  image:
    src: /logo.svg
  actions:
    - theme: brand
      text: Learn
      link: /resources/getting-started/
    - theme: alt
      text: API Reference
      link: /api/
    - theme: alt
      text: Github
      link: https://github.com/alicesaidhi/jabby
features:
  - title: Query your worlds
    details: Query your ECS worlds and figure out what entities exist using the built-in query language.
  - title: Edit entities
    details: Edit entities inside your worlds to test out new features for your project.
  - title: Insight into your systems
    details: Gain insight into how your systems perform with filtering and pausing functionality.

---
