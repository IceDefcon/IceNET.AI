/* IceNET Robotics 2026 */

#include "gui.h"

static const mainWindowType w =
{
    .xWindow = 1200,
    .yWindow = 750,
    .xGap = 5,
    .yGap = 5,
    .xLogo = 300,
    .yLogo = 50,
    .xUnit = 100,
    .yUnit = 25,
};

gui::gui() :
m_usbDevicesDetected(0),
m_fx3Handle(nullptr)
{
    std::cout << "[INFO] [CONSTRUCTOR] " << this << " :: " << __PRETTY_FUNCTION__ << std::endl;

    setupWindow();
    setupUsbDevices();
    setupDataSend();

    setupDescriptorsInterface();
    setupFlashInterface();
    setupExtensionsInterface();
    setupCommunicationInterface();
}

gui::~gui() /* implicitly virtual because QWidget::~QWidget() is virtual */
{
    std::cout << "[INFO] [DESTRUCTOR] " << this << " :: " << __PRETTY_FUNCTION__ << std::endl;

    if(m_fx3Handle != nullptr)
    {
        cyusb_release_interface(m_fx3Handle, 0);

        m_fx3Handle = nullptr;

        cyusb_close();
    }

    m_usbDevicesDetected = 0;
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
    leftLayout->addWidget(m_devicePanel, 1);
    leftLayout->addWidget(tabs, 4);

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
    QScreen *screen = QGuiApplication::primaryScreen();

    if (!screen)
    {
        return;
    }

    this->setGeometry(screen->availableGeometry());
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
    m_mainConsole->setPlainText("$ [INIT] Main Console Initialized...");

    m_instanceConsole = std::make_shared<console>(m_mainConsole);
}

void gui::setupUsbDevices()
{
    uint32_t xBase = w.xGap;
    uint32_t yBase = w.yGap;

    QFont commonLabelFont;
    QLabel *commonLabel = new QLabel("USB FX3 Devices", m_devicePanel);
    commonLabel->setGeometry(xBase, yBase, w.xLogo, w.yLogo);
    commonLabelFont.setPointSize(20);
    commonLabelFont.setBold(true);
    commonLabel->setFont(commonLabelFont);
    commonLabel->show();

    QPushButton *openLibButton = new QPushButton("REGISTER", m_devicePanel);
    openLibButton->setGeometry(xBase, yBase + w.yGap + w.yLogo, w.xUnit, w.yUnit);
    openLibButton->show();
    connect(openLibButton, &QPushButton::clicked, this, &gui::registerUsbDevices);
}

void gui::setupDataSend()
{
    uint32_t xBase = w.xGap;
    uint32_t yBase = w.yGap;

    QPushButton *sendButton = new QPushButton("SEND", m_devicePanel);
    sendButton->setGeometry(xBase, yBase + w.yGap * 2 + w.yLogo + w.yUnit, w.xUnit, w.yUnit);
    sendButton->show();

    QLineEdit *sendField = new QLineEdit(m_devicePanel);
    sendField->setGeometry(xBase + w.xGap + w.xUnit, yBase + w.yGap * 2 + w.yLogo + w.yUnit, w.xUnit, w.yUnit);
    sendField->setText("0x" + QString::number(0x1234, 16).toUpper());
    sendField->show();

    /* Send data to FX3 */
    auto sendData = [this, sendField]()
    {
        this->sendData(sendField);
    };

    /* Connect SEND button */
    connect(sendButton, &QPushButton::clicked, this, sendData);
}

void gui::sendData(QLineEdit *sendField)
{
    if(m_fx3Handle == nullptr)
    {
        std::cout << "[ERROR] [FX3] INVALID DEVICE HANDLE" << std::endl;

        return;
    }

    bool ok = false;

    uint16_t value = sendField->text().toUShort(&ok, 0);

    if(!ok)
    {
        std::cout << "[ERROR] [FX3] INVALID HEX VALUE = " << sendField->text().toStdString() << std::endl;

        return;
    }

    /*
     * FX3 uses a byte buffer. Send the 16-bit value
     * in little-endian order.
     */
    constexpr int BUFFER_SIZE = 2*sizeof(uint16_t);

    unsigned char *buffer = static_cast<unsigned char *>(malloc(BUFFER_SIZE));

    if(buffer == nullptr)
    {
        std::cout << "[ERROR] [FX3] BUFFER ALLOCATION FAILED" << std::endl;

        return;
    }

    buffer[0] = 0xAB;
    buffer[1] = 0xCD;
    buffer[2] = 0x23;
    buffer[3] = 0x67;

    constexpr unsigned char FX3_OUT_ENDPOINT = 0x01;
    constexpr unsigned int FX3_TIMEOUT_MS = 1000;

    int transferred = 0;

    int status = cyusb_bulk_transfer(
        m_fx3Handle,
        FX3_OUT_ENDPOINT,
        buffer,
        BUFFER_SIZE,
        &transferred,
        FX3_TIMEOUT_MS);

    if(status != 0)
    {
        std::cout << "[ERROR] [FX3] USB BULK TRANSFER FAILED, ERROR = " << status << std::endl;

        free(buffer);

        return;
    }

    std::cout << "[INFO] [FX3] SENT VALUE = 0x" << QString("%1").arg(value, 4, 16, QChar('0')).toUpper().toStdString() << " BYTES = " << transferred << std::endl;

    free(buffer);
}

void gui::registerUsbDevices()
{
    if(m_fx3Handle != nullptr)
    {
        std::cout << "[WARNING] [FX3] DEVICE ALREADY REGISTERED" << std::endl;

        return;
    }

    int cyusb = cyusb_open();

    m_instanceConsole->printConsole(
        INFO,
        "cyusb_open() returned = " + QString::number(cyusb)
    );

    if(cyusb < 0)
    {
        m_instanceConsole->printConsole(ERNO, "Error opening Library");

        return;
    }
    else if(cyusb == 0)
    {
        m_instanceConsole->printConsole(WARN, "No CyUSB device of interest detected");

        cyusb_close();

        return;
    }
    else
    {
        m_instanceConsole->printConsole(INFO, "Found USB Device: " + QString::number(cyusb));

        m_usbDevicesDetected = cyusb;
    }

    /*
     * Only USB device index 0 is currently supported.
     */
    m_fx3Handle = cyusb_gethandle(0);

    if(m_fx3Handle == nullptr)
    {
        std::cout << "[ERROR] [FX3] FAILED TO GET DEVICE HANDLE" << std::endl;

        m_usbDevicesDetected = 0;
        cyusb_close();

        return;
    }

    /*
     * Detach the kernel driver before claiming interface 0.
     */
    int kernelDriverActive = cyusb_kernel_driver_active(m_fx3Handle, 0);

    if(kernelDriverActive == 1)
    {
        int status = cyusb_detach_kernel_driver(m_fx3Handle, 0);

        if(status != 0)
        {
            std::cout << "[ERROR] [FX3] FAILED TO DETACH KERNEL DRIVER, ERROR = " << status << std::endl;

            m_fx3Handle = nullptr;
            m_usbDevicesDetected = 0;
            cyusb_close();

            return;
        }
    }

    /*
     * Claim USB interface 0.
     */
    int status = cyusb_claim_interface(m_fx3Handle, 0);

    if(status != 0)
    {
        std::cout << "[ERROR] [FX3] FAILED TO CLAIM INTERFACE 0, ERROR = " << status << std::endl;

        m_fx3Handle = nullptr;
        m_usbDevicesDetected = 0;
        cyusb_close();

        return;
    }

    /*
     * Select alternate interface setting 0.
     */
    status = cyusb_set_interface_alt_setting(m_fx3Handle, 0, 0);

    if(status != 0)
    {
        std::cout << "[ERROR] [FX3] FAILED TO SET ALTERNATE INTERFACE 0, ERROR = " << status << std::endl;

        cyusb_release_interface(m_fx3Handle, 0);

        m_fx3Handle = nullptr;
        m_usbDevicesDetected = 0;
        cyusb_close();

        return;
    }

    std::cout << "[INFO] [FX3] DEVICE HANDLE = " << m_fx3Handle << std::endl;

    m_instanceConsole->printConsole(
        TODO,
        "Only one USB Device Supported :: Interface(0)"
    );

    m_instanceUsbDevice = std::make_unique<device>(m_instanceConsole);
}

void gui::setupDescriptorsInterface()
{
    uint32_t xBase = w.xGap;
    uint32_t yBase = w.yGap;

    QLabel *descLabel = new QLabel("USB Descriptors", m_descPanel);
    descLabel->setGeometry(xBase, yBase, w.xLogo, w.yLogo);
    descLabel->show();
}

void gui::setupFlashInterface()
{
    uint32_t xBase = w.xGap;
    uint32_t yBase = w.yGap;

    QLabel *flashLabel = new QLabel("Fx3 Flash Interface", m_flashPanel);
    flashLabel->setGeometry(xBase, yBase, w.xLogo, w.yLogo);
    flashLabel->show();
}

void gui::setupExtensionsInterface()
{
    uint32_t xBase = w.xGap;
    uint32_t yBase = w.yGap;

    QLabel *extLabel = new QLabel("Vecdor Extensions", m_extensPanel);
    extLabel->setGeometry(xBase, yBase, w.xLogo, w.yLogo);
    extLabel->show();
}

void gui::setupCommunicationInterface()
{
    uint32_t xBase = w.xGap;
    uint32_t yBase = w.yGap;

    QLabel *commsLabel = new QLabel("USB Communication", m_commsPanel);
    commsLabel->setGeometry(xBase, yBase, w.xLogo, w.yLogo);
    commsLabel->show();
}
