/* IceNET Technology 2026 */

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

#include <thread>
#include <mutex>
#include <cmath>

#include "guiTypes.h"

class gui : public QWidget
{
    Q_OBJECT

    QPlainTextEdit *m_mainConsole;

    QWidget *m_devicePanel;
    QWidget *m_descPanel;
    QWidget *m_flashPanel;
    QWidget *m_extensPanel;
    QWidget *m_commsPanel;

    QVBoxLayout *m_deviceLayout;
    QVBoxLayout *m_descLayout;
    QVBoxLayout *m_flashLayout;
    QVBoxLayout *m_extensLayout;
    QVBoxLayout *m_commsLayout;

private slots:

    void setupWindow();
    void setupMainConsole();
    void setupDeviceInterface();

    void setupDescriptorsInterface();
    void setupFlashInterface();
    void setupExtensionsInterface();
    void setupCommunicationInterface();

public:

    gui();
    ~gui();

private slots:

};
