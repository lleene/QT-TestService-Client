#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include <TcpClient.h>
int main(int argc, char *argv[]){
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);
    qmlRegisterType<TcpClient>("lbleene.qmlcomponents", 1, 0, "TcpClient");
    QQmlApplicationEngine engine;
    engine.load(QUrl(QLatin1String("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty()) return -1;
    app.setWindowIcon(QIcon(":/icons/fedora.svg"));
    return app.exec();
}
