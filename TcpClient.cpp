#include "TcpClient.h"

TcpClient::TcpClient(QObject *parent) : QTcpSocket(parent){
    for(int i=0;i<CFG_LEN;i++) test_config[i] = '0';
    for(int i=0;i<CFG_LEN;i++) power_config[i] = '0';
    for(int i=0;i<4;i++) syn_config.amplitude[i] = 0;
    for(int i=0;i<4;i++) syn_config.frequency[i] = 0;
    for(int i=0;i<2;i++) rpi_config.voltages[i] = vsupply_code(1.8f);
    for(int i=0;i<2;i++) rpi_config.voltages[i+2] = vreference_code(1.0f);
    for(int i=0;i<4;i++) clock_dividers[i] = 0;
}

void TcpClient::make_connection(QString servername, QString serverport){
    if(state() == QAbstractSocket::UnconnectedState){
        quint16 port = serverport.toUInt();
        connectToHost(servername, port);
        if(waitForConnected(1000)){
            if(!waitForReadyRead(1000)) {
                emit newStatus(true);
            }
            else {
                buffer = readAll();
                emit newConnection(true, QString::fromUtf8(buffer));
            }
        }
        else{
            emit newConnection(false,"");
            emit newStatus(true);
        }
    }
    else{
        end_connection();
        emit newConnection(false,"");
        emit newStatus(true);
    }
}

void TcpClient::end_connection(){
    if(state() == QAbstractSocket::ConnectedState){
        send_command(END_STR);
        disconnectFromHost();
    }
    emit newConnection(false,"");
}

void TcpClient::send_command(QString command)
{
    if(state() == QAbstractSocket::ConnectedState){
        buffer = command.toUtf8() + '\0';
        write(buffer);
        if(!waitForReadyRead(1000)){ // no response
               emit newStatus(true);
        }
        else
        {
            buffer = readAll();
            if(buffer.contains("ACK")){
                buffer.clear();
                update_config_struct();
                if(command == "VYGR-CNFG") buffer.setRawData(reinterpret_cast<char*>(&rpi_config.test_register),sizeof(rpi_config.test_register));
                else if(command == "VYGR-SETP") buffer.setRawData(reinterpret_cast<char*>(&rpi_config),sizeof(rpi_config));
                else if(command == "VDAC-CNFG") buffer.setRawData(reinterpret_cast<char*>(&syn_config),sizeof(syn_config));
                else  buffer = QString("NULL-NULL").toUtf8() + '\0';
                write(buffer);
                if(!waitForReadyRead(1000)){ // no response
                       emit newStatus(true);
                }
                else{
                    buffer = readAll();
                    if(buffer.contains("ACK")) emit newStatus(false); // valid command
                    else emit newStatus(true);
                }
            }
            else emit newStatus(true);
        }
    }
    else emit newStatus(true);  // not connected
}

void TcpClient::update_config_struct(){
    rpi_config.test_register = 0;
    rpi_config.power_register = 0;
    for (int i = 0;i<CFG_LEN;i++) {
        if (test_config[CFG_LEN-i-1] == '1') rpi_config.test_register = (rpi_config.test_register<<1)+1;
        else rpi_config.test_register = rpi_config.test_register<<1;
        if (power_config[CFG_LEN-i-1] == '1') rpi_config.power_register = (rpi_config.power_register<<1)+1;
        else rpi_config.power_register = rpi_config.power_register<<1;
    }
    int temp_register;
    temp_register = clock_dividers[0] & DDWS_4b_CLK_MASK;
    temp_register = (temp_register << 4) | (clock_dividers[1] & DDWS_4b_CLK_MASK);
    temp_register = (temp_register << 4) | (clock_dividers[2] & DDWS_4b_CLK_MASK);
    temp_register = (temp_register << 4) | (clock_dividers[3] & DDWS_4b_CLK_MASK);
    rpi_config.clock_register = temp_register << DDWS_CFGWORD_OFFSET;
}

void TcpClient::print_config(){
    for(int i=0;i<CFG_LEN;i++) qDebug() << test_config[i];
    for(int i=0;i<CFG_LEN;i++) qDebug() << power_config[i];
    for(int i=0;i<4;i++) qDebug() << rpi_config.voltages[i];
    for(int i=0;i<4;i++) qDebug() << syn_config.amplitude[i] << syn_config.frequency[i];
}

void TcpClient::set_config(int index, bool val){
    if(val) test_config[index] = '1';
    else test_config[index] = '0';
}

void TcpClient::set_power(int index, bool val){ // legal bits spi_register[22:7]
    if(val) power_config[index] = '1';
    else power_config[index] = '0';
}

void TcpClient::set_voltage(int index, float voltage){
    if(index <= 1) rpi_config.voltages[index] = vsupply_code(voltage);
    else if (index <= 3) rpi_config.voltages[index] = vreference_code(voltage);
    else clock_dividers[index-4] = static_cast<int>(voltage);
}

void TcpClient::set_synth(int index, int amp, int frq){
    syn_config.amplitude[index] = amp;
    syn_config.frequency[index] = frq;
}

void TcpClient::set_index(int index, int bits, int val){
    //qDebug() << val;
    for(int i=0; i<bits; i++){
        // (val%2)? test_config[index+i] = true : test_config[index+i] = false; // MSB Last
        (val%2)? test_config[index+bits-i-1] = '1' : test_config[index+bits-i-1] = '0'; // MSB First
        val = val>>1;
    }
}

void TcpClient::str_to_file(QString data_string){
    QFile filepointer( "qml-state.data" );
    if ( filepointer.open(QIODevice::WriteOnly | QFile::Text) ){
        QTextStream stream( &filepointer );
        stream << data_string << endl;
    }
}

QString TcpClient::str_from_file(){
    QFile filepointer( "qml-state.data" );
    if ( filepointer.open(QIODevice::ReadOnly | QFile::Text) )
    {
        QTextStream stream( &filepointer );
        return stream.readAll();
    }
    else return QString();
}

// Potentiometer will set R1 R2 ratio for TPS7A87
// R1 = 25k*(CODE), R2 = 25k*(1-CODE) - where CODE is [0 1]
// Vout = 0.8*(1 + R1/R2) = 0.8 + 0.8*CODE/(1-CODE)
// CODE = (Vout - 0.8)/Vout
int TcpClient::vsupply_code(float VDD_Voltage){
  int spi_data_code;
  float mask_code = static_cast<float>(DDWS_10b_SPI_MASK);
  // Apply Limits
  if(VDD_Voltage <= 0.8f) VDD_Voltage = 0.8f + 1/mask_code;
  if(VDD_Voltage >= 5.0f) VDD_Voltage = 5.0f - 1/mask_code;
  spi_data_code =  (~static_cast<int>((( VDD_Voltage - 0.8f )/VDD_Voltage) * mask_code)) & DDWS_10b_SPI_MASK;
  return spi_data_code;
}

// Potentiometer will set R1 R2 ratio loading LTC6655 2.048V reference
// R1 = 25k*(CODE), R2 = 25k*(1-CODE) - where CODE is [0 1]
// Vref = 2.048*(R1/R2) = 2.048*CODE
// CODE = Vref/2.048
int TcpClient::vreference_code(float VREF_Voltage){
  int spi_data_code;
  float mask_code = static_cast<float>(DDWS_10b_SPI_MASK);
  // Apply Limits
  if(VREF_Voltage <= 0.0f) VREF_Voltage = 0.0f + 1/mask_code;
  if(VREF_Voltage >= 2.048f) VREF_Voltage = 2.048f - 1/(mask_code);
  spi_data_code = static_cast<int>((mask_code*VREF_Voltage)/2.048f) & DDWS_10b_SPI_MASK;
  return spi_data_code;
}
