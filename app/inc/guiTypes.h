/* IceNET Robotics 2026 */

#pragma once

typedef struct
{
    uint32_t xWindow;
    uint32_t yWindow;
    uint32_t xGap;
    uint32_t yGap;
    uint32_t xLogo;
    uint32_t yLogo;
    uint32_t xUnit;
    uint32_t yUnit;
} mainWindowType;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static constexpr const char* main_window_style =
R"(
    QWidget
    {
        background-color: #002b36;  /* Solarized Dark background */
        color: #839496;             /* Solarized base text */
        font-family: DejaVu Sans Mono;
    }

    QTabWidget::pane
    {
        border: 1px solid #073642;  /* subtle Solarized border */
        border-radius: 12px;
        background: #073642;        /* darker pane base */
    }

    QTabWidget
    {
        background: transparent;
    }

    QWidget#centralWidget
    {
        background: #073642;
    }
)";

static constexpr const char* tab_style =
R"(
    QTabWidget::pane
    {
        border: none;
        background: #073642;  /* Solarized pane base */
    }

    QTabBar::tab
    {
        width: 20px;
        height: 100px;

        font-family: DejaVu Sans Mono;
        font-size: 10pt;
        font-weight: bold;

        color: #839496;  /* base text */
        background: #073642;

        border-radius: 0px;  /* fully squared */
        margin: 2px;         /* small gap between tabs */
        padding: 4px;        /* tight internal padding */
    }

    QTabBar::tab:hover
    {
        background: #586e75;  /* Solarized highlight */
        color: #fdf6e3;       /* light text */
    }

    QTabBar::tab:selected
    {
        background: #268bd2;  /* Solarized blue for selected */
        color: #fdf6e3;       /* bright selected text */
    }
)";

static constexpr const char* console_style =
R"(
    QPlainTextEdit {
        background-color: #073642;   /* brighter than main bg */
        color: #839496;              /* Solarized base text */
        border: 1px solid #586e75;  /* subtle border */
        selection-background-color: #586e75;
    }
)";
