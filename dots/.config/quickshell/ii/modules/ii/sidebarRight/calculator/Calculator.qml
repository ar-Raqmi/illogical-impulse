import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

FocusScope {
    id: root
    implicitHeight: 300 
    focus: true
    
    property string displayValue: "0"
    property string previousValue: ""
    property string operation: ""
    property bool newNumber: true

    function formatNumber(value) {
        if (value === "Error" || value === "NaN") return value;
        
        let parts = value.toString().split(".");
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        return parts.join(".");
    }

    function handleDigit(digit) {
        if (newNumber) {
            displayValue = digit;
            newNumber = false;
        } else {
            if (displayValue === "0" && digit !== ".") {
                displayValue = digit;
            } else {
                // Prevent multiple decimals
                if (digit === "." && displayValue.includes(".")) return;
                displayValue += digit;
            }
        }
    }

    function handleOperation(op) {
        if (operation !== "" && !newNumber) {
            calculate();
        }
        previousValue = displayValue;
        operation = op;
        newNumber = true;
    }

    function calculate() {
        if (operation === "") return;
        let prev = parseFloat(previousValue);
        let current = parseFloat(displayValue);
        let result = 0;
        switch(operation) {
            case "+": result = prev + current; break;
            case "-": result = prev - current; break;
            case "*": result = prev * current; break;
            case "/": 
                if (current === 0) {
                    displayValue = "Error";
                    operation = "";
                    newNumber = true;
                    return;
                }
                result = prev / current; 
                break;
        }
        displayValue = Number(result.toFixed(10)).toString();
        operation = "";
        newNumber = true;
    }

    function clear() { displayValue = "0"; previousValue = ""; operation = ""; newNumber = true; }
    function backspace() {
        if (displayValue.length > 1) displayValue = displayValue.slice(0, -1);
        else { displayValue = "0"; newNumber = true; }
    }

    Keys.onPressed: (event) => {
        if (event.text >= "0" && event.text <= "9") {
            handleDigit(event.text);
            event.accepted = true;
        } else if (event.text === "." || event.text === ",") {
            handleDigit(".");
            event.accepted = true;
        } else if (event.text === "+") {
            handleOperation("+");
            event.accepted = true;
        } else if (event.text === "-") {
            handleOperation("-");
            event.accepted = true;
        } else if (event.text === "*" || event.text === "x") {
            handleOperation("*");
            event.accepted = true;
        } else if (event.text === "/") {
            handleOperation("/");
            event.accepted = true;
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.text === "=") {
            calculate();
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            backspace();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape || event.key === Qt.Key_Delete) {
            clear();
            event.accepted = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: {
            root.forceActiveFocus();
            mouse.accepted = false;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 55
            color: Appearance.colors.colLayer2
            radius: Appearance.rounding.small
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 0
                StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: root.operation ? root.formatNumber(root.previousValue) + " " + root.operation : " "
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    text: root.formatNumber(root.displayValue)
                    font.pixelSize: 20
                    font.weight: 600
                    font.family: Appearance.font.family.numbers
                    color: Appearance.colors.colOnSurface
                    elide: Text.ElideLeft
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 4
            rowSpacing: 6
            columnSpacing: 6

            CompactCalcButton { buttonText: "C"; baseColor: Appearance.colors.colErrorContainer; colText: Appearance.colors.colOnErrorContainer; onClicked: root.clear() }
            CompactCalcButton { materialIcon: "backspace"; onClicked: root.backspace() }
            CompactCalcButton { buttonText: "%"; onClicked: { root.displayValue = (parseFloat(root.displayValue) / 100).toString(); root.newNumber = true; } }
            CompactCalcButton { buttonText: "÷"; op: true; onClicked: root.handleOperation("/") }

            CompactCalcButton { buttonText: "7"; onClicked: root.handleDigit("7") }
            CompactCalcButton { buttonText: "8"; onClicked: root.handleDigit("8") }
            CompactCalcButton { buttonText: "9"; onClicked: root.handleDigit("9") }
            CompactCalcButton { materialIcon: "close"; op: true; onClicked: root.handleOperation("*") }

            CompactCalcButton { buttonText: "4"; onClicked: root.handleDigit("4") }
            CompactCalcButton { buttonText: "5"; onClicked: root.handleDigit("5") }
            CompactCalcButton { buttonText: "6"; onClicked: root.handleDigit("6") }
            CompactCalcButton { materialIcon: "remove"; op: true; onClicked: root.handleOperation("-") }

            CompactCalcButton { buttonText: "1"; onClicked: root.handleDigit("1") }
            CompactCalcButton { buttonText: "2"; onClicked: root.handleDigit("2") }
            CompactCalcButton { buttonText: "3"; onClicked: root.handleDigit("3") }
            CompactCalcButton { materialIcon: "add"; op: true; onClicked: root.handleOperation("+") }

            CompactCalcButton { buttonText: "0"; Layout.columnSpan: 2; Layout.fillWidth: true; onClicked: root.handleDigit("0") }
            CompactCalcButton { buttonText: "."; onClicked: root.handleDigit(".") }
            CompactCalcButton { materialIcon: "equal"; baseColor: Appearance.colors.colPrimary; colText: Appearance.colors.colOnPrimary; onClicked: root.calculate() }
        }
    }

    component CompactCalcButton: RippleButton {
        property bool op: false
        property string materialIcon: ""
        property color colText: op ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurface
        property color baseColor: op ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
        
        colBackgroundHover: ColorUtils.mix(baseColor, colText, 0.9)
        Layout.fillWidth: true
        Layout.fillHeight: true
        buttonRadius: Appearance.rounding.small
        colBackground: baseColor
        colRipple: ColorUtils.mix(baseColor, colText, 0.8)
        
        contentItem: Item {
            anchors.centerIn: parent
            MaterialSymbol { 
                anchors.centerIn: parent
                visible: materialIcon !== ""
                text: materialIcon
                iconSize: 18
                color: colText
            }
            StyledText { 
                anchors.centerIn: parent
                visible: materialIcon === ""
                text: buttonText
                font.pixelSize: 16
                font.weight: 500
                font.family: Appearance.font.family.numbers
                color: colText
            }
        }
    }
}