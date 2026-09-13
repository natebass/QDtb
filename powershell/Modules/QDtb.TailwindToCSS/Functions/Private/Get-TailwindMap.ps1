function Get-TailwindMap {
    <#
    .SYNOPSIS
    Provides a comprehensive set of data structures mapping Tailwind CSS utilities to CSS properties.
    .DESCRIPTION
    This function generates and returns a hashtable containing all the necessary data for the conversion process.
    This includes color palettes, spacing scales, font sizes, breakpoints, and a large map for static,
    one-to-one utility class conversions. Centralizing this data makes the main conversion logic cleaner
    and easier to maintain. This is a private helper function for the module.
    #>

    #region Core Data Structures
    $map = @{
        breakpoints = @{
            'sm' = '640px';
            'md' = '768px';
            'lg' = '1024px';
            'xl' = '1280px';
            '2xl' = '1536px';
        };

        colors = @{
            'slate' = @{ '50' = '#f8fafc'; '100' = '#f1f5f9'; '200' = '#e2e8f0'; '300' = '#cbd5e1'; '400' = '#94a3b8'; '500' = '#64748b'; '600' = '#475569'; '700' = '#334155'; '800' = '#1e293b'; '900' = '#0f172a'; '950' = '#020617' };
            'gray' = @{ '50' = '#f9fafb'; '100' = '#f3f4f6'; '200' = '#e5e7eb'; '300' = '#d1d5db'; '400' = '#9ca3af'; '500' = '#6b7280'; '600' = '#4b5563'; '700' = '#374151'; '800' = '#1f2937'; '900' = '#111827'; '950' = '#030712' };
            'zinc' = @{ '50' = '#fafafa'; '100' = '#f4f4f5'; '200' = '#e4e4e7'; '300' = '#d4d4d8'; '400' = '#a1a1aa'; '500' = '#71717a'; '600' = '#52525b'; '700' = '#3f3f46'; '800' = '#27272a'; '900' = '#18181b'; '950' = '#09090b' };
            'neutral' = @{ '50' = '#fafafa'; '100' = '#f5f5f5'; '200' = '#e5e5e5'; '300' = '#d4d4d4'; '400' = '#a3a3a3'; '500' = '#737373'; '600' = '#525252'; '700' = '#404040'; '800' = '#262626'; '900' = '#171717'; '950' = '#0a0a0a' };
            'stone' = @{ '50' = '#fafaf9'; '100' = '#f5f5f4'; '200' = '#e7e5e4'; '300' = '#d6d3d1'; '400' = '#a8a29e'; '500' = '#78716c'; '600' = '#57534e'; '700' = '#44403c'; '800' = '#292524'; '900' = '#1c1917'; '950' = '#0c0a09' };
            'red' = @{ '50' = '#fef2f2'; '100' = '#fee2e2'; '200' = '#fecaca'; '300' = '#fca5a5'; '400' = '#f87171'; '500' = '#ef4444'; '600' = '#dc2626'; '700' = '#b91c1c'; '800' = '#991b1b'; '900' = '#7f1d1d'; '950' = '#450a0a' };
            'orange' = @{ '50' = '#fff7ed'; '100' = '#ffedd5'; '200' = '#fed7aa'; '300' = '#fdba74'; '400' = '#fb923c'; '500' = '#f97316'; '600' = '#ea580c'; '700' = '#c2410c'; '800' = '#9a3412'; '900' = '#7c2d12'; '950' = '#431407' };
            'amber' = @{ '50' = '#fffbeb'; '100' = '#fef3c7'; '200' = '#fde68a'; '300' = '#fcd34d'; '400' = '#fbbf24'; '500' = '#f59e0b'; '600' = '#d97706'; '700' = '#b45309'; '800' = '#92400e'; '900' = '#78350f'; '950' = '#451a03' };
            'yellow' = @{ '50' = '#fefce8'; '100' = '#fef9c3'; '200' = '#fef08a'; '300' = '#fde047'; '400' = '#facc15'; '500' = '#eab308'; '600' = '#ca8a04'; '700' = '#a16207'; '800' = '#854d0e'; '900' = '#713f12'; '950' = '#422006' };
            'lime' = @{ '50' = '#f7fee7'; '100' = '#ecfccb'; '200' = '#d9f99d'; '300' = '#bef264'; '400' = '#a3e635'; '500' = '#84cc16'; '600' = '#65a30d'; '700' = '#4d7c0f'; '800' = '#3f6212'; '900' = '#365314'; '950' = '#1a2e05' };
            'green' = @{ '50' = '#f0fdf4'; '100' = '#dcfce7'; '200' = '#bbf7d0'; '300' = '#86efac'; '400' = '#4ade80'; '500' = '#22c55e'; '600' = '#16a34a'; '700' = '#15803d'; '800' = '#166534'; '900' = '#14532d'; '950' = '#052e16' };
            'emerald' = @{ '50' = '#ecfdf5'; '100' = '#d1fae5'; '200' = '#a7f3d0'; '300' = '#6ee7b7'; '400' = '#34d399'; '500' = '#10b981'; '600' = '#059669'; '700' = '#047857'; '800' = '#065f46'; '900' = '#064e3b'; '950' = '#022c22' };
            'teal' = @{ '50' = '#f0fdfa'; '100' = '#ccfbf1'; '200' = '#99f6e4'; '300' = '#5eead4'; '400' = '#2dd4bf'; '500' = '#14b8a6'; '600' = '#0d9488'; '700' = '#0f766e'; '800' = '#115e59'; '900' = '#134e4a'; '950' = '#042f2e' };
            'cyan' = @{ '50' = '#ecfeff'; '100' = '#cffafe'; '200' = '#a5f3fc'; '300' = '#67e8f9'; '400' = '#22d3ee'; '500' = '#06b6d4'; '600' = '#0891b2'; '700' = '#0e7490'; '800' = '#155e75'; '900' = '#164e63'; '950' = '#083344' };
            'sky' = @{ '50' = '#f0f9ff'; '100' = '#e0f2fe'; '200' = '#bae6fd'; '300' = '#7dd3fc'; '400' = '#38bdf8'; '500' = '#0ea5e9'; '600' = '#0284c7'; '700' = '#0369a1'; '800' = '#075985'; '900' = '#0c4a6e'; '950' = '#082f49' };
            'blue' = @{ '50' = '#eff6ff'; '100' = '#dbeafe'; '200' = '#bfdbfe'; '300' = '#93c5fd'; '400' = '#60a5fa'; '500' = '#3b82f6'; '600' = '#2563eb'; '700' = '#1d4ed8'; '800' = '#1e40af'; '900' = '#1e3a8a'; '950' = '#172554' };
            'indigo' = @{ '50' = '#eef2ff'; '100' = '#e0e7ff'; '200' = '#c7d2fe'; '300' = '#a5b4fc'; '400' = '#818cf8'; '500' = '#6366f1'; '600' = '#4f46e5'; '700' = '#4338ca'; '800' = '#3730a3'; '900' = '#312e81'; '950' = '#1e1b4b' };
            'violet' = @{ '50' = '#f5f3ff'; '100' = '#ede9fe'; '200' = '#ddd6fe'; '300' = '#c4b5fd'; '400' = '#a78bfa'; '500' = '#8b5cf6'; '600' = '#7c3aed'; '700' = '#6d28d9'; '800' = '#5b21b6'; '900' = '#4c1d95'; '950' = '#2e1065' };
            'purple' = @{ '50' = '#faf5ff'; '100' = '#f3e8ff'; '200' = '#e9d5ff'; '300' = '#d8b4fe'; '400' = '#c084fc'; '500' = '#a855f7'; '600' = '#9333ea'; '700' = '#7e22ce'; '800' = '#6b21a8'; '900' = '#581c87'; '950' = '#3b0764' };
            'fuchsia' = @{ '50' = '#fdf4ff'; '100' = '#fae8ff'; '200' = '#f5d0fe'; '300' = '#f0abfc'; '400' = '#e879f9'; '500' = '#d946ef'; '600' = '#c026d3'; '700' = '#a21caf'; '800' = '#86198f'; '900' = '#701a75'; '950' = '#4a044e' };
            'pink' = @{ '50' = '#fdf2f8'; '100' = '#fce7f3'; '200' = '#fbcfe8'; '300' = '#f9a8d4'; '400' = '#f472b6'; '500' = '#ec4899'; '600' = '#db2777'; '700' = '#be185d'; '800' = '#9d174d'; '900' = '#831843'; '950' = '#500724' };
            'rose' = @{ '50' = '#fff1f2'; '100' = '#ffe4e6'; '200' = '#fecdd3'; '300' = '#fda4af'; '400' = '#fb7185'; '500' = '#f43f5e'; '600' = '#e11d48'; '700' = '#be123c'; '800' = '#9f1239'; '900' = '#881337'; '950' = '#4c0519' };
            'black' = '#000';
            'white' = '#fff';
            'transparent' = 'transparent';
            'current' = 'currentColor';
        };

        spacing = @{
            '0' = '0px'; 'px' = '1px'; '0.5' = '0.125rem'; '1' = '0.25rem'; '1.5' = '0.375rem'; '2' = '0.5rem';
            '2.5' = '0.625rem'; '3' = '0.75rem'; '3.5' = '0.875rem'; '4' = '1rem'; '5' = '1.25rem'; '6' = '1.5rem';
            '7' = '1.75rem'; '8' = '2rem'; '9' = '2.25rem'; '10' = '2.5rem'; '11' = '2.75rem'; '12' = '3rem';
            '14' = '3.5rem'; '16' = '4rem'; '20' = '5rem'; '24' = '6rem'; '28' = '7rem'; '32' = '8rem';
            '36' = '9rem'; '40' = '10rem'; '44' = '11rem'; '48' = '12rem'; '52' = '13rem'; '56' = '14rem';
            '60' = '15rem'; '64' = '16rem'; '72' = '18rem'; '80' = '20rem'; '96' = '24rem';
        };

        fontSizes = @{
            'xs' = @('0.75rem', '1rem'); 'sm' = @('0.875rem', '1.25rem'); 'base' = @('1rem', '1.5rem');
            'lg' = @('1.125rem', '1.75rem'); 'xl' = @('1.25rem', '1.75rem'); '2xl' = @('1.5rem', '2rem');
            '3xl' = @('1.875rem', '2.25rem'); '4xl' = @('2.25rem', '2.5rem'); '5xl' = @('3rem', '1');
            '6xl' = @('3.75rem', '1'); '7xl' = @('4.5rem', '1'); '8xl' = @('6rem', '1'); '9xl' = @('8rem', '1');
        };

        staticUtilities = @{
            # Layout
            'box-border' = 'box-sizing: border-box;';
            'box-content' = 'box-sizing: content-box;';
            'block' = 'display: block;';
            'inline-block' = 'display: inline-block;';
            'inline' = 'display: inline;';
            'flex' = 'display: flex;';
            'inline-flex' = 'display: inline-flex;';
            'table' = 'display: table;';
            'inline-table' = 'display: inline-table;';
            'table-caption' = 'display: table-caption;';
            'table-cell' = 'display: table-cell;';
            'table-column' = 'display: table-column;';
            'table-column-group' = 'display: table-column-group;';
            'table-footer-group' = 'display: table-footer-group;';
            'table-header-group' = 'display: table-header-group;';
            'table-row-group' = 'display: table-row-group;';
            'table-row' = 'display: table-row;';
            'flow-root' = 'display: flow-root;';
            'grid' = 'display: grid;';
            'inline-grid' = 'display: inline-grid;';
            'contents' = 'display: contents;';
            'list-item' = 'display: list-item;';
            'hidden' = 'display: none;';
            'float-right' = 'float: right;';
            'float-left' = 'float: left;';
            'float-none' = 'float: none;';
            'clear-left' = 'clear: left;';
            'clear-right' = 'clear: right;';
            'clear-both' = 'clear: both;';
            'clear-none' = 'clear: none;';
            'isolate' = 'isolation: isolate;';
            'isolation-auto' = 'isolation: auto;';
            'object-contain' = 'object-fit: contain;';
            'object-cover' = 'object-fit: cover;';
            'object-fill' = 'object-fit: fill;';
            'object-none' = 'object-fit: none;';
            'object-scale-down' = 'object-fit: scale-down;';
            'overflow-auto' = 'overflow: auto;';
            'overflow-hidden' = 'overflow: hidden;';
            'overflow-clip' = 'overflow: clip;';
            'overflow-visible' = 'overflow: visible;';
            'overflow-scroll' = 'overflow: scroll;';
            'overflow-x-auto' = 'overflow-x: auto;';
            'overflow-y-auto' = 'overflow-y: auto;';
            'overflow-x-hidden' = 'overflow-x: hidden;';
            'overflow-y-hidden' = 'overflow-y: hidden;';
            'overscroll-auto' = 'overscroll-behavior: auto;';
            'overscroll-contain' = 'overscroll-behavior: contain;';
            'overscroll-none' = 'overscroll-behavior: none;';
            'overscroll-y-auto' = 'overscroll-behavior-y: auto;';
            'overscroll-y-contain' = 'overscroll-behavior-y: contain;';
            'overscroll-y-none' = 'overscroll-behavior-y: none;';
            'overscroll-x-auto' = 'overscroll-behavior-x: auto;';
            'overscroll-x-contain' = 'overscroll-behavior-x: contain;';
            'overscroll-x-none' = 'overscroll-behavior-x: none;';
            'static' = 'position: static;';
            'fixed' = 'position: fixed;';
            'absolute' = 'position: absolute;';
            'relative' = 'position: relative;';
            'sticky' = 'position: sticky;';
            'visible' = 'visibility: visible;';
            'invisible' = 'visibility: hidden;';
            'collapse' = 'visibility: collapse;';

            # Flex & Grid
            'flex-row' = 'flex-direction: row;';
            'flex-row-reverse' = 'flex-direction: row-reverse;';
            'flex-col' = 'flex-direction: column;';
            'flex-col-reverse' = 'flex-direction: column-reverse;';
            'flex-wrap' = 'flex-wrap: wrap;';
            'flex-wrap-reverse' = 'flex-wrap: wrap-reverse;';
            'flex-nowrap' = 'flex-wrap: nowrap;';
            'flex-1' = 'flex: 1 1 0%;';
            'flex-auto' = 'flex: 1 1 auto;';
            'flex-initial' = 'flex: 0 1 auto;';
            'flex-none' = 'flex: none;';
            'flex-grow' = 'flex-grow: 1;';
            'flex-grow-0' = 'flex-grow: 0;';
            'flex-shrink' = 'flex-shrink: 1;';
            'flex-shrink-0' = 'flex-shrink: 0;';
            'justify-normal' = 'justify-content: normal;';
            'justify-start' = 'justify-content: flex-start;';
            'justify-end' = 'justify-content: flex-end;';
            'justify-center' = 'justify-content: center;';
            'justify-between' = 'justify-content: space-between;';
            'justify-around' = 'justify-content: space-around;';
            'justify-evenly' = 'justify-content: space-evenly;';
            'justify-stretch' = 'justify-content: stretch;';
            'justify-items-start' = 'justify-items: start;';
            'justify-items-end' = 'justify-items: end;';
            'justify-items-center' = 'justify-items: center;';
            'justify-items-stretch' = 'justify-items: stretch;';
            'justify-self-auto' = 'justify-self: auto;';
            'justify-self-start' = 'justify-self: start;';
            'justify-self-end' = 'justify-self: end;';
            'justify-self-center' = 'justify-self: center;';
            'justify-self-stretch' = 'justify-self: stretch;';
            'content-normal' = 'align-content: normal;';
            'content-center' = 'align-content: center;';
            'content-start' = 'align-content: flex-start;';
            'content-end' = 'align-content: flex-end;';
            'content-between' = 'align-content: space-between;';
            'content-around' = 'align-content: space-around;';
            'content-evenly' = 'align-content: space-evenly;';
            'content-baseline' = 'align-content: baseline;';
            'content-stretch' = 'align-content: stretch;';
            'items-start' = 'align-items: flex-start;';
            'items-end' = 'align-items: flex-end;';
            'items-center' = 'align-items: center;';
            'items-baseline' = 'align-items: baseline;';
            'items-stretch' = 'align-items: stretch;';
            'self-auto' = 'align-self: auto;';
            'self-start' = 'align-self: flex-start;';
            'self-end' = 'align-self: flex-end;';
            'self-center' = 'align-self: center;';
            'self-stretch' = 'align-self: stretch;';
            'self-baseline' = 'align-self: baseline;';
            'place-content-center' = 'place-content: center;';
            'place-content-start' = 'place-content: start;';
            'place-content-end' = 'place-content: end;';
            'place-content-between' = 'place-content: space-between;';
            'place-content-around' = 'place-content: space-around;';
            'place-content-evenly' = 'place-content: space-evenly;';
            'place-content-baseline' = 'place-content: baseline;';
            'place-content-stretch' = 'place-content: stretch;';
            'place-items-start' = 'place-items: start;';
            'place-items-end' = 'place-items: end;';
            'place-items-center' = 'place-items: center;';
            'place-items-stretch' = 'place-items: stretch;';
            'place-self-auto' = 'place-self: auto;';
            'place-self-start' = 'place-self: start;';
            'place-self-end' = 'place-self: end;';
            'place-self-center' = 'place-self: center;';
            'place-self-stretch' = 'place-self: stretch;';

            # Typography
            'antialiased' = '-webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale;';
            'subpixel-antialiased' = '-webkit-font-smoothing: auto; -moz-osx-font-smoothing: auto;';
            'italic' = 'font-style: italic;';
            'not-italic' = 'font-style: normal;';
            'font-thin' = 'font-weight: 100;';
            'font-extralight' = 'font-weight: 200;';
            'font-light' = 'font-weight: 300;';
            'font-normal' = 'font-weight: 400;';
            'font-medium' = 'font-weight: 500;';
            'font-semibold' = 'font-weight: 600;';
            'font-bold' = 'font-weight: 700;';
            'font-extrabold' = 'font-weight: 800;';
            'font-black' = 'font-weight: 900;';
            'normal-nums' = 'font-variant-numeric: normal;';
            'ordinal' = 'font-variant-numeric: ordinal;';
            'slashed-zero' = 'font-variant-numeric: slashed-zero;';
            'lining-nums' = 'font-variant-numeric: lining-nums;';
            'oldstyle-nums' = 'font-variant-numeric: oldstyle-nums;';
            'proportional-nums' = 'font-variant-numeric: proportional-nums;';
            'tabular-nums' = 'font-variant-numeric: tabular-nums;';
            'diagonal-fractions' = 'font-variant-numeric: diagonal-fractions;';
            'stacked-fractions' = 'font-variant-numeric: stacked-fractions;';
            'list-inside' = 'list-style-position: inside;';
            'list-outside' = 'list-style-position: outside;';
            'text-left' = 'text-align: left;';
            'text-center' = 'text-align: center;';
            'text-right' = 'text-align: right;';
            'text-justify' = 'text-align: justify;';
            'text-start' = 'text-align: start;';
            'text-end' = 'text-align: end;';
            'underline' = 'text-decoration-line: underline;';
            'overline' = 'text-decoration-line: overline;';
            'line-through' = 'text-decoration-line: line-through;';
            'no-underline' = 'text-decoration-line: none;';
            'decoration-solid' = 'text-decoration-style: solid;';
            'decoration-double' = 'text-decoration-style: double;';
            'decoration-dotted' = 'text-decoration-style: dotted;';
            'decoration-dashed' = 'text-decoration-style: dashed;';
            'decoration-wavy' = 'text-decoration-style: wavy;';
            'uppercase' = 'text-transform: uppercase;';
            'lowercase' = 'text-transform: lowercase;';
            'capitalize' = 'text-transform: capitalize;';
            'normal-case' = 'text-transform: none;';
            'text-ellipsis' = 'text-overflow: ellipsis;';
            'text-clip' = 'text-overflow: clip;';
            'truncate' = 'overflow: hidden; text-overflow: ellipsis; white-space: nowrap;';
            'text-wrap' = 'text-wrap: wrap;';
            'text-nowrap' = 'text-wrap: nowrap;';
            'text-balance' = 'text-wrap: balance;';
            'text-pretty' = 'text-wrap: pretty;';
            'align-baseline' = 'vertical-align: baseline;';
            'align-top' = 'vertical-align: top;';
            'align-middle' = 'vertical-align: middle;';
            'align-bottom' = 'vertical-align: bottom;';
            'align-text-top' = 'vertical-align: text-top;';
            'align-text-bottom' = 'vertical-align: text-bottom;';
            'align-sub' = 'vertical-align: sub;';
            'align-super' = 'vertical-align: super;';
            'whitespace-normal' = 'white-space: normal;';
            'whitespace-nowrap' = 'white-space: nowrap;';
            'whitespace-pre' = 'white-space: pre;';
            'whitespace-pre-line' = 'white-space: pre-line;';
            'whitespace-pre-wrap' = 'white-space: pre-wrap;';
            'whitespace-break-spaces' = 'white-space: break-spaces;';
            'break-normal' = 'overflow-wrap: normal; word-break: normal;';
            'break-words' = 'overflow-wrap: break-word;';
            'break-all' = 'word-break: break-all;';
            'break-keep' = 'word-break: keep-all;';
            'hyphens-none' = 'hyphens: none;';
            'hyphens-manual' = 'hyphens: manual;';
            'hyphens-auto' = 'hyphens: auto;';

            # Backgrounds
            'bg-fixed' = 'background-attachment: fixed;';
            'bg-local' = 'background-attachment: local;';
            'bg-scroll' = 'background-attachment: scroll;';
            'bg-clip-border' = 'background-clip: border-box;';
            'bg-clip-padding' = 'background-clip: padding-box;';
            'bg-clip-content' = 'background-clip: content-box;';
            'bg-clip-text' = 'background-clip: text;';
            'bg-origin-border' = 'background-origin: border-box;';
            'bg-origin-padding' = 'background-origin: padding-box;';
            'bg-origin-content' = 'background-origin: content-box;';
            'bg-repeat' = 'background-repeat: repeat;';
            'bg-no-repeat' = 'background-repeat: no-repeat;';
            'bg-repeat-x' = 'background-repeat: repeat-x;';
            'bg-repeat-y' = 'background-repeat: repeat-y;';
            'bg-repeat-round' = 'background-repeat: round;';
            'bg-repeat-space' = 'background-repeat: space;';
            'bg-auto' = 'background-size: auto;';
            'bg-cover' = 'background-size: cover;';
            'bg-contain' = 'background-size: contain;';

            # Borders
            'border-solid' = 'border-style: solid;';
            'border-dashed' = 'border-style: dashed;';
            'border-dotted' = 'border-style: dotted;';
            'border-double' = 'border-style: double;';
            'border-hidden' = 'border-style: hidden;';
            'border-none' = 'border-style: none;';
            'outline-none' = 'outline: 2px solid transparent; outline-offset: 2px;';
            'outline' = 'outline-style: solid;';
            'outline-dashed' = 'outline-style: dashed;';
            'outline-dotted' = 'outline-style: dotted;';
            'outline-double' = 'outline-style: double;';

            # Effects
            'mix-blend-normal' = 'mix-blend-mode: normal;';
            'mix-blend-multiply' = 'mix-blend-mode: multiply;';
            'mix-blend-screen' = 'mix-blend-mode: screen;';
            'mix-blend-overlay' = 'mix-blend-mode: overlay;';
            'mix-blend-darken' = 'mix-blend-mode: darken;';
            'mix-blend-lighten' = 'mix-blend-mode: lighten;';
            'mix-blend-color-dodge' = 'mix-blend-mode: color-dodge;';
            'mix-blend-color-burn' = 'mix-blend-mode: color-burn;';
            'mix-blend-hard-light' = 'mix-blend-mode: hard-light;';
            'mix-blend-soft-light' = 'mix-blend-mode: soft-light;';
            'mix-blend-difference' = 'mix-blend-mode: difference;';
            'mix-blend-exclusion' = 'mix-blend-mode: exclusion;';
            'mix-blend-hue' = 'mix-blend-mode: hue;';
            'mix-blend-saturation' = 'mix-blend-mode: saturation;';
            'mix-blend-color' = 'mix-blend-mode: color;';
            'mix-blend-luminosity' = 'mix-blend-mode: luminosity;';
            'bg-blend-normal' = 'background-blend-mode: normal;';
            'bg-blend-multiply' = 'background-blend-mode: multiply;';
            'bg-blend-screen' = 'background-blend-mode: screen;';
            'bg-blend-overlay' = 'background-blend-mode: overlay;';
            'bg-blend-darken' = 'background-blend-mode: darken;';
            'bg-blend-lighten' = 'background-blend-mode: lighten;';
            'bg-blend-color-dodge' = 'background-blend-mode: color-dodge;';
            'bg-blend-color-burn' = 'background-blend-mode: color-burn;';
            'bg-blend-hard-light' = 'background-blend-mode: hard-light;';
            'bg-blend-soft-light' = 'background-blend-mode: soft-light;';
            'bg-blend-difference' = 'background-blend-mode: difference;';
            'bg-blend-exclusion' = 'background-blend-mode: exclusion;';
            'bg-blend-hue' = 'background-blend-mode: hue;';
            'bg-blend-saturation' = 'background-blend-mode: saturation;';
            'bg-blend-color' = 'background-blend-mode: color;';
            'bg-blend-luminosity' = 'background-blend-mode: luminosity;';

            # Tables
            'border-collapse' = 'border-collapse: collapse;';
            'border-separate' = 'border-collapse: separate;';
            'table-auto' = 'table-layout: auto;';
            'table-fixed' = 'table-layout: fixed;';
            'caption-top' = 'caption-side: top;';
            'caption-bottom' = 'caption-side: bottom;';

            # Transitions & Animation
            'transition-none' = 'transition-property: none;';
            'transition-all' = 'transition-property: all; transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1); transition-duration: 150ms;';
            'transition' = 'transition-property: color, background-color, border-color, text-decoration-color, fill, stroke, opacity, box-shadow, transform, filter, backdrop-filter; transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1); transition-duration: 150ms;';
            'transition-colors' = 'transition-property: color, background-color, border-color, text-decoration-color, fill, stroke; transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1); transition-duration: 150ms;';
            'transition-opacity' = 'transition-property: opacity; transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1); transition-duration: 150ms;';
            'transition-shadow' = 'transition-property: box-shadow; transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1); transition-duration: 150ms;';
            'transition-transform' = 'transition-property: transform; transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1); transition-duration: 150ms;';
            'ease-linear' = 'transition-timing-function: linear;';
            'ease-in' = 'transition-timing-function: cubic-bezier(0.4, 0, 1, 1);';
            'ease-out' = 'transition-timing-function: cubic-bezier(0, 0, 0.2, 1);';
            'ease-in-out' = 'transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);';
            'animate-none' = 'animation: none;';
            'animate-spin' = 'animation: spin 1s linear infinite;';
            'animate-ping' = 'animation: ping 1s cubic-bezier(0, 0, 0.2, 1) infinite;';
            'animate-pulse' = 'animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;';
            'animate-bounce' = 'animation: bounce 1s infinite;';

            # Transforms
            'transform-gpu' = 'transform: translate(var(--tw-translate-x), var(--tw-translate-y)) rotate(var(--tw-rotate)) skewX(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y));';
            'transform-none' = 'transform: none;';

            # Interactivity
            'appearance-none' = 'appearance: none;';
            'cursor-auto' = 'cursor: auto;';
            'cursor-default' = 'cursor: default;';
            'cursor-pointer' = 'cursor: pointer;';
            'cursor-wait' = 'cursor: wait;';
            'cursor-text' = 'cursor: text;';
            'cursor-move' = 'cursor: move;';
            'cursor-help' = 'cursor: help;';
            'cursor-not-allowed' = 'cursor: not-allowed;';
            'pointer-events-none' = 'pointer-events: none;';
            'pointer-events-auto' = 'pointer-events: auto;';
            'resize-none' = 'resize: none;';
            'resize-y' = 'resize: vertical;';
            'resize-x' = 'resize: horizontal;';
            'resize' = 'resize: both;';
            'scroll-auto' = 'scroll-behavior: auto;';
            'scroll-smooth' = 'scroll-behavior: smooth;';
            'snap-start' = 'scroll-snap-align: start;';
            'snap-end' = 'scroll-snap-align: end;';
            'snap-center' = 'scroll-snap-align: center;';
            'snap-align-none' = 'scroll-snap-align: none;';
            'snap-normal' = 'scroll-snap-stop: normal;';
            'snap-always' = 'scroll-snap-stop: always;';
            'touch-auto' = 'touch-action: auto;';
            'touch-none' = 'touch-action: none;';
            'select-none' = 'user-select: none;';
            'select-text' = 'user-select: text;';
            'select-all' = 'user-select: all;';
            'select-auto' = 'user-select: auto;';
            'will-change-auto' = 'will-change: auto;';
            'will-change-scroll' = 'will-change: scroll-position;';
            'will-change-contents' = 'will-change: contents;';
            'will-change-transform' = 'will-change: transform;';

            # SVG
            'fill-none' = 'fill: none;';
            'fill-current' = 'fill: currentColor;';
            'stroke-current' = 'stroke: currentColor;';
        };
    }
    #endregion

    return $map
}
