import { defineConfig } from "vitepress";
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'

// https://vitepress.dev/reference/site-config
export default defineConfig({

    title: "jabby",
    titleTemplate: ":title - A debugger for JECS",
    description: "A debugger for JECS",
    base: "/jabby/",
    head: [
        ["link", { rel: "icon", href: "/jabby/logo.svg" }],
        ["link", { rel: "preconnect", href: "https://fonts.googleapis.com" }],
        ["link", { rel: "preconnect", href: "https://fonts.gstatic.com", crossorgin: '' }],
        ["link", { rel: "stylesheet", href: "https://fonts.googleapis.com/css2?family=JetBrains+Mono:ital,wght@0,100..800;1,100..800&display=swap" }]
    ],
    cleanUrls: true,

    vite: {
        ssr: {
            noExternal: [
                '@nolebase/vitepress-plugin-highlight-targeted-heading'
            ]
        }
    },
    
    markdown: {
        config(md) {
            md.use(tabsMarkdownPlugin);
        }
    },

    themeConfig: {
        logo: "/jabby.svg",

        search: {
            provider: "local"
        },

        footer: {
            message: 'Released under the MIT License.',
        },

        // https://vitepress.dev/reference/default-theme-config
        nav: [
            { text: "Home", link: "/" },
            { text: "Resources", link: "/resources/" },
            { text: "API", link: "/api/"},
        ],

        sidebar: {
            "/api/": [
                { text: "Glossary", link: "/api/" },
                { text: "jabby", link: "/api/jabby/", collapsed: false, items: [
                    { text: "vm_id", link: "/api/jabby/vm_id/" },
                    { text: "set_check_function", link: "/api/jabby/set_check_function/" },
                    { text: "obtain_client", link: "/api/jabby/obtain_client/" },
                    { text: "register", link: "/api/jabby/register/" },
                    { text: "applets", link: "/api/applets/" },
                ] },
                { text: "Client", link: "/api/client/", collapsed: false, items: [
                    { text: "spawn_app", link: "/api/client/spawn_app/" },
                    { text: "unmount_all", link: "/api/client/unmount_all/" },
                    { text: "apps", link: "/api/client/apps/" },
                ]},
                { text: "Applets", link: "/api/applets/", collapsed: false, items: [
                    { text: "Scheduler", link: "/api/applets/scheduler/", },
                    { text: "World", link: "/api/applets/world/" },
                ] },
                { text: "Scheduler", link: "/api/scheduler", collapsed: false, items: [
                    { text: "get_system_data", link: "/api/scheduler/get_system_data/" },
                    { text: "register_system", link: "/api/scheduler/register_system/" },
                    { text: "set_system_data", link: "/api/scheduler/set_system_data/" },
                    { text: "remove_system", link: "/api/scheduler/remove_system/" },
                    { text: "run", link: "/api/scheduler/run/" },
                ] }
            ],
            "/resources/": [
                { text: "Resources", link: "/resources/" },
                { text: "Getting Started", collapsed: false, items: [
                    { text: "Installation", link: "/resources/getting-started/1-install/" },
                    { text: "Setting up", link: "/resources/getting-started/2-setting-up/" },
                    { text: "Connecting to your world", link: "/resources/getting-started/3-world/" },
                ]},
                { text: "Querying Language", link: "/resources/querying-language/" }
            ]
        },

        socialLinks: [
            { icon: "github", link: "https://github.com/alicesaidhi/jabby" }
        ]
    }
})