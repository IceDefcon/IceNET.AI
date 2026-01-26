/* IceNET Technology 2026 */

#pragma once

#include <QPlainTextEdit>
#include <QApplication>
#include <QPushButton>
#include <QVBoxLayout>
#include <QMessageBox>
#include <QDateTime>
#include <QLineEdit>
#include <QCheckBox>
#include <QPainter>
#include <QPixmap>
#include <QDialog>
#include <QWidget>
#include <QObject>
#include <QThread>
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

private slots:

    void setupWindow();
    void setupMainConsole();

public:

    gui();
    ~gui();

private slots:

};
