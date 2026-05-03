#-------------------------------------------------
# controlcenter.pro (Qt5)
#-------------------------------------------------

TEMPLATE = app
TARGET   = app

# Source files
SOURCES += main.cpp \
           controlcenter.cpp \
           fx2_download.cpp \
           fx3_download.cpp \
           streamer.cpp

# Header files
HEADERS += ../include/controlcenter.h

# Qt Designer forms
FORMS += controlcenter.ui

# Qt5 modules
QT += core gui widgets network

# External libraries
LIBS += -L../lib -lcyusb -lusb-1.0

# Include paths
INCLUDEPATH += ../include
