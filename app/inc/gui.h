/* IceNET Robotics 2026 */

#pragma once

#include <QSystemSemaphore>
#include <QGuiApplication>
#include <QPlainTextEdit>
#include <QSharedMemory>
#include <QApplication>
#include <QPushButton>
#include <QVBoxLayout>
#include <QMessageBox>
#include <QTabWidget>
#include <QDateTime>
#include <QLineEdit>
#include <QCheckBox>
#include <QPainter>
#include <QPointer>
#include <QPixmap>
#include <QDialog>
#include <QWidget>
#include <QObject>
#include <QThread>
#include <QTabBar>
#include <QWindow>
#include <QScreen>
#include <QCursor>
#include <QDebug>
#include <QImage>
#include <QLabel>
#include <QTimer>
#include <QFont>

#include <iostream>
#include <memory>
#include <chrono>
#include <thread>
#include <mutex>
#include <cmath>

#include "device.h"
#include "console.h"
#include "guiTypes.h"

class gui : public QWidget
{
    Q_OBJECT

    QWidget *m_devicePanel;
    QWidget *m_descPanel;
    QWidget *m_flashPanel;
    QWidget *m_extensPanel;
    QWidget *m_commsPanel;

    QPlainTextEdit *m_mainConsole;
    std::shared_ptr<console> m_instanceConsole;

    int m_usbDevicesDetected;
    std::unique_ptr<device> m_instanceUsbDevice;

private slots:

    void setupWindow();
    void setupMainConsole();
    // void printConsole(consoleType type, const QString &message);

    void setupUsbDevices();
    void registerUsbDevices();

    void setupDescriptorsInterface();
    void setupFlashInterface();
    void setupExtensionsInterface();
    void setupCommunicationInterface();

public:

    gui();
    ~gui();  /* implicitly virtual because QWidget::~QWidget() is virtual */

private slots:

};
