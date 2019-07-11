#ifndef TcpClient_H
#define TCPCLIENT_H
#include <QObject>
#include <QFile>
#include <QTcpSocket> // Connect
#include <QHostAddress>  // QHostAddress

#define CFG_LEN 32
#define END_STR "VYGR-TERM"
#define OK_STR "ACK"
#define NK_STR "NAK"
#define DDWS_CFGWORD_OFFSET 7
#define DDWS_10b_SPI_MASK 0x3FF
#define DDWS_4b_CLK_MASK 0xF

struct  system_config_block{
  int test_register;
  int power_register;
  int clock_register;
  int voltages[4];
};

struct  synth_config_block{
  int amplitude[4];
  int frequency[4];
};

class TcpClient : public QTcpSocket
{
    Q_OBJECT

private:
    QByteArray buffer;
    char test_config[CFG_LEN];
    char power_config[CFG_LEN];
    int clock_dividers[4];
    struct system_config_block rpi_config;
    struct synth_config_block syn_config;
    void print_config();
    void update_config_struct();
    int vsupply_code(float VDD_Voltage);
    int vreference_code(float VREF_Voltage);

public:
    explicit TcpClient(QObject *parent = Q_NULLPTR);

public slots:
    // Network functions
    void make_connection(QString servername, QString serverport);
    void end_connection();
    void send_command(QString command);
    // Configuration Handles
    void set_config(int index, bool val);
    void set_power(int index, bool val);
    void set_voltage(int index, float val);
    void set_synth(int index, int amp, int frq);
    void set_index(int index, int bits, int val);
    // Utility functions
    void str_to_file(QString data_string);
    QString str_from_file();

signals:
    void newStatus(bool status_flag);
    void newConnection(bool status_flag, QString host_id);
};

#endif // TCPCLIENT_H
