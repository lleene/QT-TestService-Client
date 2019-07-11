import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import QtQuick.Extras 1.4

import lbleene.qmlcomponents 1.0

ApplicationWindow {

    id: mainappwindow

    TcpClient {
        id: tcpclient
        onNewConnection: {
            connect_status.active=status_flag;
            mainappwindow.title=host_id;
        }
        onNewStatus: {
            command_status.active=status_flag;
        }
    }

    visible: true

    header: RowLayout {
        id: header_row
        height: mainappwindow.height*0.1
        width: mainappwindow.width
        anchors.horizontalCenter: mainappwindow.horizontalCenter
        anchors.top: mainappwindow.top
        spacing: 10

        Button {
            id: connect_btn
            Layout.minimumWidth: parent.width/6
            Layout.fillWidth: true
            Layout.fillHeight:true
            text: "Connect"
            onClicked: {
                if(connect_status.active) tcpclient.end_connection()
                else tcpclient.make_connection(server_name_input.text,server_port_input.text)

                if(connect_status.active) connect_btn.text = "Disconnect"
                else connect_btn.text = "Connect"
            }
        }

        StatusIndicator{
            color: "green"
            id: connect_status
        }

        StatusIndicator{
            color: "red"
            id: command_status
        }

        Button {
            id: exit_btn
            Layout.minimumWidth: parent.width/6
            Layout.fillWidth: true
            Layout.fillHeight:true
            onClicked: {
                tcpclient.end_connection()
                Qt.quit()
            }
            text: "Exit"
        }
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: tabBar.currentIndex

        function load_gui_state(){  // command_grid, config_grid, synth_grid, power_grid
            var state_list =  tcpclient.str_from_file().split(',')
            var j = 0
            var i
            var k
            for (k = 0; k < swipeView.contentChildren.length; k++){
                for (i = 0; i < swipeView.contentChildren[k].contentChildren[0].children.length & state_list[j] !== ""; i++)
                {
                    if(swipeView.contentChildren[k].contentChildren[0].children[i].qml_type === "checkbox"){
                        swipeView.contentChildren[k].contentChildren[0].children[i].checked = (state_list[j] === "true")
                        j++
                    }
                    if(swipeView.contentChildren[k].contentChildren[0].children[i].qml_type === "slider"){
                        swipeView.contentChildren[k].contentChildren[0].children[i].value = parseFloat(state_list[j])
                        j++
                    }
                    if(swipeView.contentChildren[k].contentChildren[0].children[i].qml_type === "combobox"){
                        swipeView.contentChildren[k].contentChildren[0].children[i].currentIndex = parseInt(state_list[j])
                        j++
                    }
                    if(swipeView.contentChildren[k].contentChildren[0].children[i].qml_type === "textfield"){
                        swipeView.contentChildren[k].contentChildren[0].children[i].text = state_list[j]
                        j++
                    }
                }
            }
        }
        function save_gui_state(){   // command_grid, config_grid, synth_grid, power_grid
            var state_list = "" ;
            var i
            var k
            for (k = 0; k < swipeView.contentChildren.length; k++){
                for (i = 0; i < swipeView.contentChildren[k].contentChildren[0].children.length; i++)
                {
                    if(swipeView.contentChildren[k].contentChildren[0].children[i].qml_type === "checkbox"){
                        state_list += swipeView.contentChildren[k].contentChildren[0].children[i].checked + ","
                    }
                    if(swipeView.contentChildren[k].contentChildren[0].children[i].qml_type === "slider"){
                        state_list += swipeView.contentChildren[k].contentChildren[0].children[i].value.toPrecision(3) + ","
                    }
                    if(swipeView.contentChildren[k].contentChildren[0].children[i].qml_type === "combobox"){
                        state_list += swipeView.contentChildren[k].contentChildren[0].children[i].currentIndex + ","
                    }
                    if(swipeView.contentChildren[k].contentChildren[0].children[i].qml_type === "textfield"){
                        state_list += swipeView.contentChildren[k].contentChildren[0].children[i].text + ","
                    }
                }
            }
            tcpclient.str_to_file(state_list)
        }

        Page {
            id:page_sample
            Grid {
                spacing: 20
                columns: 2
                anchors.centerIn: parent
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter

                // default to local host or rpi at 129.31.147.109 or 169.254.120.146 from dhcp
                //TextField {Layout.preferredWidth: 200; id: server_name_input; text: "129.31.147.109" }
                // TextField {Layout.preferredWidth: 200; id: server_name_input; text: "129.31.147.18" }
                //TextField {Layout.preferredWidth: 200; id: server_name_input; text: "169.254.120.146" }
                //TextField {Layout.preferredWidth: 200; id: server_name_input; text: "localhost" }

                Text { width: 60; text: "Host ID:"; horizontalAlignment: Text.AlignHCenter }
                TextField {Layout.preferredWidth: 240; id: server_name_input; text: "129.31.147.156"
                    property string qml_type: "textfield"}
                Text { width: 60; text: "Port #:"; horizontalAlignment: Text.AlignHCenter }
                TextField {Layout.preferredWidth: 240; id: server_port_input; text: "3490";
                    property string qml_type: "textfield"}
                Button { id: load_btn; text: "LOAD"; width: 100; height: 50;
                    onClicked: swipeView.load_gui_state();
                }
                Button { id: save_btn; text: "SAVE"; width: 100; height: 50;
                    onClicked: swipeView.save_gui_state();
                }
            }
        }

        Page {
            Grid {
                id: command_grid
                anchors.centerIn: parent
                spacing: 20
                columns: 2
                Repeater {
                  id:   command_buttons
                  model :  [ "CLOK-STRT","CLOK-STOP","VYGR-SETP","VYGR-CNFG", "VYGR-RECD","VDAC-STRT", "VDAC-STOP", "VDAC-CNFG"]
                  Button { text: modelData; width: 100; height: 50;
                      onClicked: tcpclient.send_command(modelData)
                  }
                }
                CheckBox { id: master_box; width: 100; text: "Master"; checked: false;
                    onCheckStateChanged: tcpclient.set_config(30,master_box.checked);
                    property string qml_type: "checkbox"
                }
                Text { width: 100; text: "  "; horizontalAlignment: Text.AlignHCenter}
            }
        }

        Page {
            Grid {
                id: config_grid
                anchors.centerIn: parent
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter
                spacing: 5
                columns: 2

                Repeater {
                  id:  config_options
                  model :  ["Self","!Reset","O0","MES2","MES1","!DWA","!CLE","ASE","DOUT"]
                  property variant index_list: [1,2,3,4,5,6,7,8,9] // bit allocations
                  CheckBox { width: 150; text: modelData; checked: false;
                      onCheckStateChanged: tcpclient.set_config(config_options.index_list[index],config_options.itemAt(index).checked)
                      property string qml_type: "checkbox"
                  }
                }
            }
        }

        Page {
            Grid {
                id: synth_grid
                anchors.centerIn: parent
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter
                spacing: 5
                columns: 3
                Text { width: 100; text: "Channel"; horizontalAlignment: Text.AlignHCenter }
                Text { width: 100; text: "Frequency"; horizontalAlignment: Text.AlignHCenter }
                Text { width: 100; text: "Amplitude"; horizontalAlignment: Text.AlignHCenter }
                Text { width: 100; text: "CH 1"; horizontalAlignment: Text.AlignHCenter }
                Slider { id: ch1_frq; width: 100; from: 0; stepSize: 1; to: 255; value: 0;
                    snapMode: Slider.SnapAlways
                    onValueChanged: tcpclient.set_synth(0,64*ch1_amp.value.toFixed(),64*ch1_frq.value.toFixed())
                    property string qml_type: "slider"
                }
                Slider { id: ch1_amp; width: 100; from: 0; stepSize: 1; to: 255; value: 0;
                    snapMode: Slider.SnapAlways
                    onValueChanged: tcpclient.set_synth(0,64*ch1_amp.value.toFixed(),64*ch1_frq.value.toFixed())
                    property string qml_type: "slider"
                }
                Text { width: 100; text: "CH 2"; horizontalAlignment: Text.AlignHCenter }
                Slider { id: ch2_frq; width: 100; from: 0; stepSize: 1; to: 255; value: 0;
                    snapMode: Slider.SnapAlways
                    onValueChanged: tcpclient.set_synth(1,64*ch2_amp.value.toFixed(),64*ch2_frq.value.toFixed())
                    property string qml_type: "slider"
                }
                Slider { id: ch2_amp; width: 100; from: 0; stepSize: 1; to: 255; value: 0;
                    snapMode: Slider.SnapAlways
                    onValueChanged: tcpclient.set_synth(1,64*ch2_amp.value.toFixed(),64*ch2_frq.value.toFixed())
                    property string qml_type: "slider"
                }
                Text { width: 100; text: "CH 3"; horizontalAlignment: Text.AlignHCenter }
                Slider { id: ch3_frq; width: 100; from: 0; stepSize: 1; to: 255; value: 0;
                    snapMode: Slider.SnapAlways
                    onValueChanged: tcpclient.set_synth(2,64*ch3_amp.value.toFixed(),64*ch3_frq.value.toFixed())
                    property string qml_type: "slider"
                }
                Slider { id: ch3_amp; width: 100; from: 0; stepSize: 1; to: 255; value: 0;
                    snapMode: Slider.SnapAlways
                    onValueChanged: tcpclient.set_synth(2,64*ch3_amp.value.toFixed(),64*ch3_frq.value.toFixed())
                    property string qml_type: "slider"
                }
                Text { width: 100; text: "CH 4"; horizontalAlignment: Text.AlignHCenter }
                Slider { id: ch4_frq; width: 100; from: 0; stepSize: 1; to: 255; value: 0;
                    snapMode: Slider.SnapAlways
                    onValueChanged: tcpclient.set_synth(3,64*ch4_amp.value.toFixed(),64*ch4_frq.value.toFixed())
                    property string qml_type: "slider"
                }
                Slider { id: ch4_amp; width: 100; from: 0; stepSize: 1; to: 255; value: 0;
                    snapMode: Slider.SnapAlways
                    onValueChanged: tcpclient.set_synth(3,64*ch4_amp.value.toFixed(),64*ch4_frq.value.toFixed())
                    property string qml_type: "slider"
                }
                CheckBox { id: pause_sdm; text: "Pause"; checked: false;
                    property string qml_type: "checkbox"
                    onCheckStateChanged: tcpclient.set_config(31,pause_sdm.checked) // TBI
                }
            }
        }

        Page {
            Grid {
                id: power_grid
                anchors.centerIn: parent
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter
                spacing: 5
                columns: 3

                Text { id: adp_tag; width:125; text: "A/D:1.8V/1.8V";
                }
                Slider { id: ap_volt; width: 125; from: 0.8; stepSize: 0.05; to: 3; value: 1.8;
                    snapMode: Slider.SnapAlways;
                    onValueChanged: {
                        adp_tag.text = String("A/D:").concat(ap_volt.value.toPrecision(3).toString()).concat("V/").concat(dp_volt.value.toPrecision(3).toString()).concat("V")
                        tcpclient.set_voltage(0,ap_volt.value.toPrecision(3))
                    }
                    property string qml_type: "slider"
                }
                Slider { id: dp_volt; width: 125; from: 0.8; stepSize: 0.05; to: 3; value: 1.8;
                    snapMode: Slider.SnapAlways;
                    onValueChanged: {
                        adp_tag.text = String("A/D:").concat(ap_volt.value.toPrecision(3).toString()).concat("V/").concat(dp_volt.value.toPrecision(3).toString()).concat("V")
                        tcpclient.set_voltage(1,dp_volt.value.toPrecision(3))
                    }
                    property string qml_type: "slider"
                }

                Text { id: ccm_tag; width:125; text: "R1/R2:1V/1V";
                }
                Slider { id: cm1_volt; width: 125; from: 0; stepSize: 0.05; to: 2; value: 1;
                    snapMode: Slider.SnapAlways;
                    onValueChanged: {
                        ccm_tag.text = String("R1/R2:").concat(cm1_volt.value.toPrecision(3).toString()).concat("V/").concat(cm2_volt.value.toPrecision(3).toString()).concat("V")
                        tcpclient.set_voltage(3,cm1_volt.value.toPrecision(3))
                    }
                    property string qml_type: "slider"
                }

                Slider { id: cm2_volt; width: 125; from: 0; stepSize: 0.05; to: 2; value: 1;
                    snapMode: Slider.SnapAlways;
                    onValueChanged: {
                        ccm_tag.text = String("R1/R2:").concat(cm1_volt.value.toPrecision(3).toString()).concat("V/").concat(cm2_volt.value.toPrecision(3).toString()).concat("V")
                        tcpclient.set_voltage(2,cm2_volt.value.toPrecision(3))
                    }
                    property string qml_type: "slider"
                }

                Text { id: dac_tag; width:125; text: "DAC:2b/5MHz";
                }
                Slider { id: dbc_volt; width: 125; from: 0; stepSize: 1; to: 14; value: 1;
                    snapMode: Slider.SnapAlways;
                    onValueChanged: {
                        if( dbc_volt.value <= 4 ) dac_tag.text = String("DAC:").concat(dbr_volt.value.toString()).concat("b/").concat((10/(1<<dbc_volt.value)).toPrecision(3).toString()).concat("MHz")
                        else dac_tag.text = String("DAC:").concat(dbr_volt.value.toString()).concat("b/").concat((20000/(1<<dbc_volt.value)).toPrecision(3).toString()).concat("kHz")
                        tcpclient.set_voltage(7,dbc_volt.value)
                    }
                    property string qml_type: "slider"
                }

                Slider { id: dbr_volt; width: 125; from: 0; stepSize: 1; to: 15; value: 2;
                    snapMode: Slider.SnapAlways;
                    onValueChanged: {
                        if( dbc_volt.value <= 4 ) dac_tag.text = String("DAC:").concat(dbr_volt.value.toString()).concat("b/").concat((10/(1<<dbc_volt.value)).toPrecision(3).toString()).concat("MHz")
                        else dac_tag.text = String("DAC:").concat(dbr_volt.value.toString()).concat("b/").concat((20000/(1<<dbc_volt.value)).toPrecision(3).toString()).concat("kHz")
                        tcpclient.set_voltage(6,dbr_volt.value)
                    }
                    property string qml_type: "slider"
                }

                Text { id: xbc_tag; width:125; text: "DUT:2b/5MHz"
                }
                Slider { id: xbc_volt; width: 125; from: 0; stepSize: 1; to: 14; value: 1;
                    snapMode: Slider.SnapAlways;
                    onValueChanged: {
                        if( xbc_volt.value <= 4 ) xbc_tag.text = String("DUT:").concat(xbr_volt.value.toString()).concat("b/").concat((20/(1<<xbc_volt.value)).toPrecision(3).toString()).concat("MHz")
                        else xbc_tag.text = String("DUT:").concat(xbr_volt.value.toString()).concat("b/").concat((20000/(1<<xbc_volt.value)).toPrecision(3).toString()).concat("kHz")
                        tcpclient.set_voltage(5,xbc_volt.value)
                    }
                    property string qml_type: "slider"
                }

                Slider { id: xbr_volt; width: 125; from: 0; stepSize: 1; to: 15; value: 2;
                    snapMode: Slider.SnapAlways;
                    onValueChanged: {
                        if( xbc_volt.value <= 4 ) xbc_tag.text = String("DUT:").concat(xbr_volt.value.toString()).concat("b/").concat((20/(1<<xbc_volt.value)).toPrecision(3).toString()).concat("MHz")
                        else xbc_tag.text = String("DUT:").concat(xbr_volt.value.toString()).concat("b/").concat((20000/(1<<xbc_volt.value)).toPrecision(3).toString()).concat("kHz")
                        tcpclient.set_voltage(4,xbr_volt.value)
                    }
                    property string qml_type: "slider"
                }

            }
        }

        Page {
            Grid {
                id: inout_grid
                anchors.centerIn: parent
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter
                spacing: 5
                columns: 3

                Repeater {
                    id:inout_options
                    model :  ["XTL", "MUX", "ATN", "ADC", "DAC","DPwr","APwr","O12:XO","O34:XO","I12:XO","I34:XO","X12:XO","X34:XO","TO:HIZ","TI:HIZ","TX:HIZ","DUT:OA"]
                    property variant index_list: [7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24] // bit allocations
                    CheckBox { width: 100; text: modelData; checked: false;
                      onCheckStateChanged: tcpclient.set_power(inout_options.index_list[index],inout_options.itemAt(index).checked)
                      property string qml_type: "checkbox"
                    }
                }
            }
        }

    }
    footer:
    TabBar {
        id: tabBar
        currentIndex: swipeView.currentIndex
        TabButton {
            text: "SCK"
        }
        TabButton {
            text: "CTL"
        }
        TabButton {
            text: "SYS"
        }
        TabButton {
            text: "AWG"
        }
        TabButton {
            text: "PWR"
        }
        TabButton {
            text: "I/O"
        }
    }
}
