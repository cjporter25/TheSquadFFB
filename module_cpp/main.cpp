// Qt class required to manage application-wide resources
#include <QApplication>
#include "MainWindow.h"

int main(int argc, char *argv[]) {
    // QApplication::setAttribute(Qt::AA_DontUseNativeMenuBar);

    QApplication::setApplicationName("TheSquadFFB");
    QApplication::setOrganizationName("Christopher Porter");
    QApplication::setApplicationVersion("0.1");
    // Instantiate the Qt Application object
    //      Handles event loop
    QApplication app(argc, argv);
    // Instanstiate my window
    MainWindow window;
    // Show the window
    window.show();
    // Starts the Qt event loop
    return app.exec();
}
