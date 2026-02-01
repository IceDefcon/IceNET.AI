/* IceNET Technology 2026 */

#include <iostream>
#include "gui.h"

static const mainWindowType w =
{
    .xWindow = 1200,
    .yWindow = 750,
    .xGap = 5,
    .yGap = 5,
    .xLogo = 200,
    .yLogo = 50,
    .xUnit = 50,
    .yUnit = 25,
};

gui::gui()
{
    std::cout << "[MAIN] [CONSTRUCTOR] " << this << " :: gui" << std::endl;

    setupWindow();
    setupDeviceInterface();

    setupDescriptorsInterface();
    setupFlashInterface();
    setupExtensionsInterface();
    setupCommunicationInterface();
}

gui::~gui()
{
    std::cout << "[MAIN] [DESTRUCTOR] " << this << " :: gui" << std::endl;
}

void gui::setupWindow()
{
    setWindowTitle("IceNET AI Drone Platform");
    setStyleSheet(main_window_style);

    m_devicePanel = new QWidget();
    m_descPanel   = new QWidget();
    m_flashPanel  = new QWidget();
    m_extensPanel = new QWidget();
    m_commsPanel  = new QWidget();

    m_deviceLayout = new QVBoxLayout(m_devicePanel);
    m_descLayout   = new QVBoxLayout(m_descPanel);
    m_flashLayout  = new QVBoxLayout(m_flashPanel);
    m_extensLayout = new QVBoxLayout(m_extensPanel);
    m_commsLayout  = new QVBoxLayout(m_commsPanel);

    QTabWidget *tabs = new QTabWidget();
    tabs->setTabPosition(QTabWidget::West);
    tabs->tabBar()->setShape(QTabBar::RoundedWest);
    tabs->setStyleSheet(tab_style);

    tabs->addTab(m_descPanel,   "   DESCRIPTORS   ");
    tabs->addTab(m_flashPanel,  "      FLASH      ");
    tabs->addTab(m_extensPanel, "       EXT       ");
    tabs->addTab(m_commsPanel,  "      COMMS      ");

    QVBoxLayout *leftLayout = new QVBoxLayout();
    leftLayout->addWidget(m_devicePanel, 1);  // top
    leftLayout->addWidget(tabs, 4);         // bottom (bigger)

    setupMainConsole();

    QVBoxLayout *rightLayout = new QVBoxLayout();
    rightLayout->addWidget(m_mainConsole);

    QHBoxLayout *mainLayout = new QHBoxLayout(this);
    mainLayout->addLayout(leftLayout, 2);
    mainLayout->addLayout(rightLayout, 1);

    setLayout(mainLayout);

    /* Multi-screen maximize workaround */
    QScreen *screen = QGuiApplication::screenAt(QCursor::pos());
    if (!screen)
    {
        screen = QGuiApplication::primaryScreen();
    }

    QRect geom = screen->availableGeometry();
    this->setGeometry(geom);
    this->show();
}


void gui::setupMainConsole()
{
    m_mainConsole = new QPlainTextEdit(this); // <-- parent = main window
    m_mainConsole->setReadOnly(true);

    QFont consoleFont;
    consoleFont.setFamily("Courier");
    consoleFont.setPointSize(10);
    consoleFont.setStyleHint(QFont::Monospace);
    consoleFont.setFixedPitch(true);

    m_mainConsole->setFont(consoleFont);
    m_mainConsole->setStyleSheet(console_style);
    m_mainConsole->setPlainText("[INIT] Main Console Initialized...");
}

void gui::setupDeviceInterface()
{
    QLabel *commonLabel = new QLabel("Common Interface Area");
    m_deviceLayout->addWidget(commonLabel);
    m_deviceLayout->addStretch();
}

void gui::setupDescriptorsInterface()
{
    QLabel *flashLabel = new QLabel("USB Descriptions");
    m_descLayout->addWidget(flashLabel);
    m_descLayout->addStretch();
}

void gui::setupFlashInterface()
{
    QLabel *flashLabel = new QLabel("Fx3 Interface");
    m_flashLayout->addWidget(flashLabel);
    m_flashLayout->addStretch();
}

void gui::setupExtensionsInterface()
{
    QLabel *flashLabel = new QLabel("Vecdor Extensions");
    m_extensLayout->addWidget(flashLabel);
    m_extensLayout->addStretch();
}

void gui::setupCommunicationInterface()
{
    QLabel *flashLabel = new QLabel("USB Communications");
    m_commsLayout->addWidget(flashLabel);
    m_commsLayout->addStretch();
}
