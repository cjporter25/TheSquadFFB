// Include header that defines the class
#include "MainWindow.h"
#include <QPushButton>
#include <QLabel>
#include <QMenu>
#include <QMessageBox>

// Define my own constructor
MainWindow::MainWindow(QWidget *parent)
    // Immediately calls the constructor of QMainWindow
    : QMainWindow(parent) {
    
    setWindowTitle("TheSquadFFB");  // Set Title
    resize(1920, 1080);
    setMinimumSize(960, 540);
    setMaximumSize(3840, 2160);
    setupMenus();
    }

    void MainWindow::setupMenus(){
        QMenuBar *customMenuBar = new QMenuBar();

        // File Menu
        fileMenu = new QMenu("File", this);
        quitAction = new QAction("Quit", this);
        connect(quitAction, &QAction::triggered, this, &QMainWindow::close);
        fileMenu->addAction(quitAction);
        customMenuBar->addMenu(fileMenu);
    
        // Help Menu
        helpMenu = new QMenu("Help", this);
        aboutAction = new QAction("About", this);
        connect(aboutAction, &QAction::triggered, [this]() {
            QMessageBox::about(this, "About TheSquadFFB",
                "TheSquadFFB is a Fantasy Football analytics and visualization tool.\n\n© 2025 Chris Porter");
        });
        helpMenu->addAction(aboutAction);
        customMenuBar->addMenu(helpMenu);
    
        // Explicitly set the menu bar
        setMenuBar(customMenuBar);
    }


    
    // Set fixed width x height
    // setFixedSize(1000,800);  