// Include guard, ensures the file is only included 
//      once per compilation
#ifndef MAINWINDOW_H
#define MAINWINDOW_H

// Class: Qt -> "QMainWindow". Top-level window
// Contains: Built-in menu bars, toolbars, status bars 
#include <QMainWindow>
#include <QMenuBar>
#include <QAction>

// Establish my own main window class, inheriting from 
//  "QMainWindow"
class MainWindow : public QMainWindow {
    // Macro - enables signals & slots
    Q_OBJECT

public:
    // Constructor - can take a parent widget, default is nullptr
    explicit MainWindow(QWidget *parent = nullptr);
    // Deconstructor. Compiler will use the default
    //      implementation
    ~MainWindow() = default;
private:
    void setupMenus();
    QMenu *fileMenu;
    QMenu *helpMenu;
    QAction *quitAction;
    QAction *aboutAction;
};

#endif // MAINWINDOW_H
