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
    .xUnit = 200,
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

    /* Create panels (no layouts inside) */
    m_devicePanel = new QWidget();
    m_descPanel   = new QWidget();
    m_flashPanel  = new QWidget();
    m_extensPanel = new QWidget();
    m_commsPanel  = new QWidget();

    /* Tab widget for bottom panels */
    QTabWidget *tabs = new QTabWidget();
    tabs->setTabPosition(QTabWidget::West);
    tabs->tabBar()->setShape(QTabBar::RoundedWest);
    tabs->setStyleSheet(tab_style);

    tabs->addTab(m_descPanel,   "   DESCRIPTORS   ");
    tabs->addTab(m_flashPanel,  "      FLASH      ");
    tabs->addTab(m_extensPanel, "   EXTENSIONS   ");
    tabs->addTab(m_commsPanel,  "      COMMS      ");

    /* Left layout: device panel on top, tabs below */
    QVBoxLayout *leftLayout = new QVBoxLayout();
    leftLayout->addWidget(m_devicePanel, 1); // top
    leftLayout->addWidget(tabs, 4);         // bottom (bigger)

    /* Right layout: main console */
    setupMainConsole();
    QVBoxLayout *rightLayout = new QVBoxLayout();
    rightLayout->addWidget(m_mainConsole);

    /* Main window layout: left + right */
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

int usbDevicesDetected;

void gui::setupDeviceInterface()
{
    uint32_t xBase = w.xGap;
    uint32_t yBase = w.yGap;

    QLabel *commonLabel = new QLabel("USB FX3 Devices", m_devicePanel);
    commonLabel->setGeometry(xBase, yBase, w.xLogo, w.yLogo);
    commonLabel->show();

    QPushButton *openLibButton = new QPushButton("OPEN LIB", m_devicePanel);
    openLibButton->setGeometry(xBase, yBase + w.yGap + w.yLogo, w.xUnit, w.yUnit);
    openLibButton->show();

    connect(openLibButton, &QPushButton::clicked, this, &gui::openUsbLibrary);

}


void gui::openUsbLibrary()
{
    int cyusb = cyusb_open();

    if (cyusb < 0)
    {
        std::cerr << "[ERROR] Error opening Library" << std::endl;
    }
    else if (cyusb == 0)
    {
        std::cout << "[WARN] No device found" << std::endl;
    }
    else
    {
        std::cout << "[INFO] Found USB Device: " << cyusb << std::endl;
        usbDevicesDetected = cyusb;
    }
}


void gui::setupDescriptorsInterface()
{
    uint32_t xBase = w.xGap;
    uint32_t yBase = w.yGap;

    QLabel *descLabel = new QLabel("USB Descriptors", m_descPanel);
    descLabel->setGeometry(xBase, yBase, w.xUnit, w.yUnit);
    descLabel->show();
}

void gui::setupFlashInterface()
{
    uint32_t xBase = w.xGap;
    uint32_t yBase = w.yGap;

    QLabel *flashLabel = new QLabel("Fx3 Flash Interface", m_flashPanel);
    flashLabel->setGeometry(xBase, yBase, w.xUnit, w.yUnit);
    flashLabel->show();
}

void gui::setupExtensionsInterface()
{
    uint32_t xBase = w.xGap;
    uint32_t yBase = w.yGap;

    QLabel *extLabel = new QLabel("Vecdor Extensions", m_extensPanel);
    extLabel->setGeometry(xBase, yBase, w.xUnit, w.yUnit);
    extLabel->show();
}

void gui::setupCommunicationInterface()
{
    uint32_t xBase = w.xGap;
    uint32_t yBase = w.yGap;

    QLabel *commsLabel = new QLabel("USB Communication", m_commsPanel);
    commsLabel->setGeometry(xBase, yBase, w.xUnit, w.yUnit);
    commsLabel->show();
}
