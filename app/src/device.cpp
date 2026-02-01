/* IceNET Robotics 2026 */

#include "device.h"

device::device(std::shared_ptr<console> pConsole) :
m_instanceConsole(pConsole),
m_usbHandle(nullptr),
m_configDescriptor(nullptr),
m_endPointCompanionDescriptors(nullptr),
m_usbInterface(nullptr)
{
    std::cout << "[INFO] [CONSTRUCTOR] " << this << " :: " << __PRETTY_FUNCTION__ << std::endl;

    updateDevicelist();
    getDeviceDetails();
    getConfigDetails();
}

device::~device()
{
    std::cout << "[INFO] [DESTRUCTOR] " << this << " :: " << __PRETTY_FUNCTION__ << std::endl;
}


void device::updateDevicelist()
{
    int ret;
    int index = 0;
    int interfaces;
    char msg[60];

    m_usbHandle = cyusb_gethandle(0);
    if (!m_usbHandle)
    {
        m_instanceConsole->printConsole(ERNO, "Problem with getting a handle");
    }

    sprintf(msg,"VID=%04x, PID=%04x, BusNum=%02x, Addr=%d",
        cyusb_getvendor(m_usbHandle),
        cyusb_getproduct(m_usbHandle),
        cyusb_get_busnumber(m_usbHandle),
        cyusb_get_devaddr(m_usbHandle));
    m_instanceConsole->printConsole(INFO, msg);

    ret = cyusb_get_active_config_descriptor(m_usbHandle, &m_configDescriptor);
    if (ret)
    {
        m_instanceConsole->printConsole(ERNO, "Problem with config descriptors");
    }

    if(m_configDescriptor)
    {
        interfaces = m_configDescriptor->bNumInterfaces;
        m_instanceConsole->printConsole(INFO, "Number of interfaces: " + QString::number(interfaces));
    }
    else
    {
        m_instanceConsole->printConsole(ERNO, "Missing Destriptors");
    }

    /* Detach kernel drivers from each interface to talk directly to USB */
    while (interfaces)
    {
        if (cyusb_kernel_driver_active (m_usbHandle, index))
        {
            cyusb_detach_kernel_driver (m_usbHandle, index);
        }
        index++;
        interfaces--;
    }
    cyusb_free_config_descriptor (m_configDescriptor);
}

void device::getDeviceDetails()
{
    int ret;
    char msg[60];

    m_usbHandle = cyusb_gethandle(0);
    if (!m_usbHandle)
    {
        m_instanceConsole->printConsole(ERNO, "Problem with getting a handle");
    }

    ret = cyusb_get_device_descriptor(m_usbHandle, &m_deviceDescriptors);
    if (ret)
    {
        m_instanceConsole->printConsole(ERNO, "Problem with device descriptors");
    }

    ret = cyusb_get_active_config_descriptor(m_usbHandle, &m_configDescriptor);
    if (ret)
    {
        m_instanceConsole->printConsole(ERNO, "Problem with config descriptors");
    }

    m_instanceConsole->printConsole(INFO, "-----------------------------------------------");
    m_instanceConsole->printConsole(INFO, "Device Descriptors");
    m_instanceConsole->printConsole(INFO, "-----------------------------------------------");
    sprintf(msg,"bLength             = %d",   m_deviceDescriptors.bLength);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bDescriptorType     = %d",   m_deviceDescriptors.bDescriptorType);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bcdUSB              = %d",   m_deviceDescriptors.bcdUSB);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bDeviceClass        = %d",   m_deviceDescriptors.bDeviceClass);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bDeviceSubClass     = %d",   m_deviceDescriptors.bDeviceSubClass);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bDeviceProtocol     = %d",   m_deviceDescriptors.bDeviceProtocol);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bMaxPacketSize      = %d",   m_deviceDescriptors.bMaxPacketSize0);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"idVendor            = %04x", m_deviceDescriptors.idVendor);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"idProduct           = %04x", m_deviceDescriptors.idProduct);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bcdDevice           = %d",   m_deviceDescriptors.bcdDevice);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"iManufacturer       = %d",   m_deviceDescriptors.iManufacturer);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"iProduct            = %d",   m_deviceDescriptors.iProduct);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"iSerialNumber       = %d",   m_deviceDescriptors.iSerialNumber);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bNumConfigurations  = %d",   m_deviceDescriptors.bNumConfigurations);
    m_instanceConsole->printConsole(INFO, msg);

    cyusb_free_config_descriptor(m_configDescriptor);
}

void device::getConfigDetails()
{
    int ret;
    char msg[60];

    m_usbHandle = cyusb_gethandle(0);
    if (!m_usbHandle)
    {
        m_instanceConsole->printConsole(ERNO, "Problem with getting a handle");
    }

    ret = cyusb_get_active_config_descriptor(m_usbHandle, &m_configDescriptor);
    if (ret)
    {
        m_instanceConsole->printConsole(ERNO, "Problem with config descriptors");
    }

    m_instanceConsole->printConsole(INFO, "-----------------------------------------------");
    m_instanceConsole->printConsole(INFO, "Config Desctiptors");
    m_instanceConsole->printConsole(INFO, "-----------------------------------------------");
    sprintf(msg,"bLength             = %d",   m_configDescriptor->bLength);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bDescriptorType     = %d",   m_configDescriptor->bDescriptorType);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"TotalLength         = %d",   m_configDescriptor->wTotalLength);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"Num. of interfaces  = %d",   m_configDescriptor->bNumInterfaces);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bConfigurationValue = %d",   m_configDescriptor->bConfigurationValue);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"iConfiguration      = %d",    m_configDescriptor->iConfiguration);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bmAttributes        = %d",    m_configDescriptor->bmAttributes);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"Max Power           = %04d",  m_configDescriptor->MaxPower);
    m_instanceConsole->printConsole(INFO, msg);

    m_usbInterface = m_configDescriptor->interface;

    m_instanceConsole->printConsole(INFO, "-----------------------------------------------");
    m_instanceConsole->printConsole(INFO, "Interface Desctiptors");
    m_instanceConsole->printConsole(INFO, "-----------------------------------------------");

    m_usbInterfaceDescriptors = m_usbInterface->altsetting;

    sprintf(msg,"bLength             = %d",   m_usbInterfaceDescriptors->bLength);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bDescriptorType     = %d",   m_usbInterfaceDescriptors->bDescriptorType);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bInterfaceNumber    = %d",   m_usbInterfaceDescriptors->bInterfaceNumber);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bAlternateSetting   = %d",   m_usbInterfaceDescriptors->bAlternateSetting);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bNumEndpoints       = %d",   m_usbInterfaceDescriptors->bNumEndpoints);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bInterfaceClass     = %02x", m_usbInterfaceDescriptors->bInterfaceClass);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bInterfaceSubClass  = %02x", m_usbInterfaceDescriptors->bInterfaceSubClass);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"bInterfaceProtcol   = %02x", m_usbInterfaceDescriptors->bInterfaceProtocol);
    m_instanceConsole->printConsole(INFO, msg);
    sprintf(msg,"iInterface          = %0d",  m_usbInterfaceDescriptors->iInterface);
    m_instanceConsole->printConsole(INFO, msg);

    for (int i = 0; i < m_usbInterfaceDescriptors->bNumEndpoints; ++i)
    {
        m_instanceConsole->printConsole(INFO, "-----------------------------------------------");
        m_instanceConsole->printConsole(INFO, "Endpoint Desctiptors [" + QString::number(i) + "]");
        m_instanceConsole->printConsole(INFO, "-----------------------------------------------");
        m_instanceConsole->printConsole(INFO, msg);
        m_endPointDescriptors = m_usbInterfaceDescriptors->endpoint;

        libusb_get_ss_endpoint_companion_descriptor (NULL, m_endPointDescriptors, &m_endPointCompanionDescriptors);

        sprintf(msg,"bLength             = %0d",  m_endPointDescriptors[i].bLength);
        m_instanceConsole->printConsole(INFO, msg);
        sprintf(msg,"bDescriptorType     = %0d",  m_endPointDescriptors[i].bDescriptorType);
        m_instanceConsole->printConsole(INFO, msg);
        sprintf(msg,"bEndpointAddress    = %02x", m_endPointDescriptors[i].bEndpointAddress);
        m_instanceConsole->printConsole(INFO, msg);
        sprintf(msg,"bmAttributes        = %d",   m_endPointDescriptors[i].bmAttributes);
        m_instanceConsole->printConsole(INFO, msg);
        sprintf(msg,"wMaxPacketSize      = %04x", (m_endPointDescriptors[i].wMaxPacketSize));
        m_instanceConsole->printConsole(INFO, msg);
        sprintf(msg,"bInterval           = %d",   m_endPointDescriptors[i].bInterval);
        m_instanceConsole->printConsole(INFO, msg);
        sprintf(msg,"bRefresh            = %d",   m_endPointDescriptors[i].bRefresh);
        m_instanceConsole->printConsole(INFO, msg);
        sprintf(msg,"bSynchAddress       = %d",   m_endPointDescriptors[i].bSynchAddress);
        m_instanceConsole->printConsole(INFO, msg);
        sprintf(msg,"</ENDPOINT>");
        m_instanceConsole->printConsole(INFO, msg);
    }

    cyusb_free_config_descriptor(m_configDescriptor);
}
