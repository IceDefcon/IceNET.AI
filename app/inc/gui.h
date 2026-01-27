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

    QWidget *m_flash;
    QWidget *m_config;
    QWidget *m_comms;

private slots:

    void setupWindow();
    void setupMainConsole();
    void setupFlashInterface();

public:

    gui();
    ~gui();

private slots:

};
