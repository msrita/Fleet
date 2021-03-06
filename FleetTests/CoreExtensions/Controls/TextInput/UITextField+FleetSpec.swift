import XCTest
import Nimble
import Fleet

class UITextField_FleetSpec: XCTestCase {
    var subject: UITextField!
    var delegate: TestTextFieldDelegate!
    var recorder: UIControlEventRecorder!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        let tuple = createCompleteTextFieldAndDelegate()
        subject = tuple.textField
        delegate = tuple.delegate
        recorder = UIControlEventRecorder()
        recorder.registerAllEvents(for: subject)
        try! Test.embedViewIntoMainApplicationWindow(subject)
    }

    override func tearDown() {
        subject.removeFromSuperview()
        super.tearDown()
    }

    func createCompleteTextFieldAndDelegate() -> (textField: UITextField, delegate: TestTextFieldDelegate) {
        let textField = UITextField(frame: CGRect(x: 100,y: 100,width: 100,height: 100))
        let delegate = TestTextFieldDelegate()
        textField.delegate = delegate

        textField.isHidden = false
        textField.isEnabled = true

        return (textField, delegate)
    }

    func test_startEditing_whenTextFieldIsFullyAvailable_putsFocusIntoTheTextField() {
        try! subject.startEditing()

        expect(self.subject.isFirstResponder).to(beTrue())
    }

    func test_startEditing_whenTextFieldIsFullyAvailable_sendsControlEventsAppropriately() {
        try! subject.startEditing()

        expect(self.subject.isFirstResponder).to(beTrue())
        expect(self.recorder.recordedEvents).to(equal([
            .touchDown,
            .allTouchEvents,
            .editingDidBegin,
            .allEditingEvents
        ]))
    }

    func test_startEditing_whenTextFieldFailsToBecomeFirstResponder_raisesException() {
        // If the text field is not in the window, it will never succeed to become first responder.
        let textFieldNotInWindow = UITextField(frame: CGRect(x: 100,y: 100,width: 100,height: 100))

        textFieldNotInWindow.isHidden = false
        textFieldNotInWindow.isEnabled = true

        expect { try textFieldNotInWindow.startEditing() }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "Could not edit UITextField: Text field failed to become first responder. This can happen if the field is not part of the window's hierarchy.", userInfo: nil, closure: nil)
        )
        expect(textFieldNotInWindow.isFirstResponder).to(beFalse())
    }

    func test_startEditing_whenTextFieldIsHidden_raisesException() {
        subject.isHidden = true

        expect { try self.subject.startEditing() }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "UITextField unavailable for editing: Text field is not visible.", userInfo: nil, closure: nil)
        )
        expect(self.subject.isFirstResponder).to(beFalse())
    }

    func test_startEditing_whenTextFieldIsNotEnabled_raisesException() {
        subject.isEnabled = false

        expect { try self.subject.startEditing() }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "UITextField unavailable for editing: Text field is not enabled.", userInfo: nil, closure: nil)
        )
        expect(self.subject.isFirstResponder).to(beFalse())
    }

    func test_startEditing_whenDelegateAllowsEditing_callsDelegateMethodsAppropriately() {
        delegate.shouldAllowBeginEditing = true

        try! subject.startEditing()

        expect(self.delegate.didCallShouldBeginEditing).to(beTrue())
        expect(self.delegate.didCallDidBeginEditing).to(beTrue())
    }

    func test_startEditing_whenDelegateDoesNotAllowEditing_callsDelegateMethodsAppropriately() {
        delegate.shouldAllowBeginEditing = false

        try! subject.startEditing()

        expect(self.delegate.didCallShouldBeginEditing).to(beTrue())
        expect(self.delegate.didCallDidBeginEditing).to(beFalse())
        expect(self.delegate.didCallShouldClear).to(beFalse())
    }

    func test_startEditing_whenDelegateDoesNotAllowEditing_stillSendsTouchDownControlEvent() {
        delegate.shouldAllowBeginEditing = false

        try! subject.startEditing()

        expect(self.recorder.recordedEvents).to(equal([
            .touchDown,
            .allTouchEvents
        ]))
    }

    func test_startEditing_whenAnotherTextFieldWasSelected_whenDelegateAllowsEditing_callsDelegateMethodsAppropriately() {
        let tuple = createCompleteTextFieldAndDelegate()
        let otherTextField = tuple.textField
        let otherDelegate = tuple.delegate
        try! Test.embedViewIntoMainApplicationWindow(otherTextField)

        otherDelegate.shouldAllowBeginEditing = true
        delegate.shouldAllowBeginEditing = true

        try! otherTextField.startEditing()
        try! subject.startEditing()

        expect(self.delegate.didCallShouldBeginEditing).to(beTrue())
        expect(self.delegate.didCallDidBeginEditing).to(beTrue())
        expect(otherDelegate.didCallShouldEndEditing).to(beTrue())
        expect(otherDelegate.didCallDidEndEditing).to(beTrue())
    }

    func test_startEditing_whenAnotherTextFieldWasSelected_whenDelegateAllowsEditing_sendsAllControlEvents() {
        let tuple = createCompleteTextFieldAndDelegate()
        let otherTextField = tuple.textField
        let otherDelegate = tuple.delegate
        try! Test.embedViewIntoMainApplicationWindow(otherTextField)

        otherDelegate.shouldAllowBeginEditing = true
        delegate.shouldAllowBeginEditing = true

        try! otherTextField.startEditing()
        try! subject.startEditing()

        expect(self.recorder.recordedEvents).to(equal([
            .touchDown,
            .allTouchEvents,
            .editingDidBegin,
            .allEditingEvents
        ]))
    }

    func test_startEditing_whenAnotherTextFieldWasSelected_whenDelegateDoesNotAllowEditing_callsDelegateMethodsAppropriately() {
        let tuple = createCompleteTextFieldAndDelegate()
        let otherTextField = tuple.textField
        let otherDelegate = tuple.delegate
        try! Test.embedViewIntoMainApplicationWindow(otherTextField)

        otherDelegate.shouldAllowBeginEditing = true
        delegate.shouldAllowBeginEditing = false

        try! otherTextField.startEditing()
        try! subject.startEditing()

        expect(self.delegate.didCallShouldBeginEditing).to(beTrue())
        expect(self.delegate.didCallDidBeginEditing).to(beFalse())
        expect(otherDelegate.didCallShouldEndEditing).to(beFalse())
        expect(otherDelegate.didCallDidEndEditing).to(beFalse())
    }

    func test_startEditing_whenAlreadyFirstResponder_doesNothing() {
        delegate.shouldAllowBeginEditing = true

        try! subject.startEditing()
        delegate.resetState()
        try! subject.startEditing()

        expect(self.delegate.didCallShouldBeginEditing).to(beFalse())
    }

    func test_stopEditing_whenTextFieldIsFullyAvailable_removesFocusFromTheTextField() {
        try! subject.startEditing()
        try! subject.stopEditing()

        expect(self.subject.isFirstResponder).to(beFalse())
    }

    func test_stopEditing_whenTextFieldIsFullyAvailable_sendsControlEvents() {
        try! subject.startEditing()
        recorder.erase()
        try! subject.stopEditing()

        expect(self.recorder.recordedEvents).to(equal([
            .editingDidEnd,
            .allEditingEvents
        ]))
    }

    func test_stopEditing_whenNotFirstResponder_raisesException() {
        expect { try self.subject.stopEditing() }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "Could not edit UITextField: Must start editing the text field before you can stop editing it.", userInfo: nil, closure: nil)
        )
    }

    func test_stopEditing_whenDelegateAllowsEditingToEnd_callsDelegateMethodsAppropriately() {
        try! subject.startEditing()
        delegate.resetState()
        delegate.shouldAllowEndEditing = true

        try! subject.stopEditing()

        expect(self.delegate.didCallShouldEndEditing).to(beTrue())
        expect(self.delegate.didCallDidEndEditing).to(beTrue())
        expect(self.subject.isFirstResponder).to(beFalse())
    }

    func test_type_typesGivenTextIntoTextField() {
        try! subject.startEditing()
        try! subject.type(text: "turtle magic")

        expect(self.subject.text).to(equal("turtle magic"))
    }

    func test_type_sendsControlEvents() {
        try! subject.startEditing()
        recorder.erase()
        try! subject.type(text: "four")

        // One `.editingChanged` event for each letter typed.
        expect(self.recorder.recordedEvents).to(equal([
            .editingChanged,
            .allEditingEvents,
            .editingChanged,
            .allEditingEvents,
            .editingChanged,
            .allEditingEvents,
            .editingChanged,
            .allEditingEvents
        ]))
    }

    func test_type_whenNotFirstResponder_raisesException() {
        expect { try self.subject.type(text: "turtle magic") }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "Could not edit UITextField: Must start editing the text field before text can be typed into it.", userInfo: nil, closure: nil)
        )
    }

    func test_type_whenDelegateAllowsTextChanges_callsDelegateMethodsAppropriately() {
        delegate.shouldAllowChangeText = true
        try! subject.startEditing()
        try! subject.type(text: "turtle magic")

        expect(self.delegate.textChanges).to(equal(["t", "u", "r", "t", "l", "e", " ", "m", "a", "g", "i", "c"]))
        expect(self.delegate.textRanges.count).to(equal(12))
        expect(self.delegate.textRanges[0].location).to(equal(0))
        expect(self.delegate.textRanges[0].length).to(equal(0))
        expect(self.delegate.textRanges[9].location).to(equal(9))
        expect(self.delegate.textRanges[9].length).to(equal(0))
    }

    func test_type_whenDelegateDoesNotAllowTextChanges_callsDelegateMethodsAppropriately() {
        delegate.shouldAllowChangeText = false
        try! subject.startEditing()
        try! subject.type(text: "turtle magic")

        expect(self.delegate.textChanges).to(equal([]))
        expect(self.delegate.textRanges.count).to(equal(12))
        expect(self.delegate.textRanges[0].location).to(equal(0))
        expect(self.delegate.textRanges[0].length).to(equal(0))
        expect(self.delegate.textRanges[9].location).to(equal(0))
        expect(self.delegate.textRanges[9].length).to(equal(0))
        expect(self.subject.text).to(equal(""))
    }

    func test_type_whenDelegateDoesNotAllowTextChanges_sendsNoEvents() {
        delegate.shouldAllowChangeText = false
        try! subject.startEditing()
        recorder.erase()
        try! subject.type(text: "turtle magic")

        expect(self.recorder.recordedEvents).to(equal([]))
    }

    func test_type_whenNoDelegate_typesGivenTextIntoTextField() {
        try! subject.startEditing()
        subject.delegate = nil
        try! subject.type(text: "turtle magic")

        expect(self.subject.text).to(equal("turtle magic"))
    }

    func test_type_whenNoDelegate_sendsControlEvents() {
        try! subject.startEditing()
        subject.delegate = nil
        recorder.erase()
        try! subject.type(text: "four")

        // One `.editingChanged` event for each letter typed.
        expect(self.recorder.recordedEvents).to(equal([
            .editingChanged,
            .allEditingEvents,
            .editingChanged,
            .allEditingEvents,
            .editingChanged,
            .allEditingEvents,
            .editingChanged,
            .allEditingEvents
        ]))
    }

    func test_paste_putsGivenTextIntoTextField() {
        try! subject.startEditing()
        try! subject.paste(text: "turtle magic")

        expect(self.subject.text).to(equal("turtle magic"))
    }

    func test_paste_sendsControlEvents() {
        try! subject.startEditing()
        recorder.erase()
        try! subject.paste(text: "turtle magic")

        expect(self.recorder.recordedEvents).to(equal([
            .editingChanged,
            .allEditingEvents
        ]))
    }

    func test_paste_whenNotFirstResponder_raisesException() {
        expect { try self.subject.paste(text: "turtle magic") }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "Could not edit UITextField: Must start editing the text field before text can be pasted into it.", userInfo: nil, closure: nil)
        )
    }

    func test_paste_whenDelegateAllowsTextChanges_callsDelegateMethodsAppropriately() {
        delegate.shouldAllowChangeText = true
        try! subject.startEditing()
        try! subject.paste(text: "turtle magic")

        expect(self.delegate.textChanges).to(equal(["turtle magic"]))
        expect(self.delegate.textRanges.count).to(equal(1))
        expect(self.delegate.textRanges[0].location).to(equal(0))
        expect(self.delegate.textRanges[0].length).to(equal(0))
    }

    func test_paste_whenDelegateDoesNotAllowTextChanges_callsDelegateMethodsAppropriately() {
        delegate.shouldAllowChangeText = false
        try! subject.startEditing()
        try! subject.paste(text: "turtle magic")

        expect(self.subject.text).to(equal(""))
        expect(self.delegate.textChanges).to(equal([]))
        expect(self.delegate.textRanges.count).to(equal(1))
        expect(self.delegate.textRanges[0].location).to(equal(0))
        expect(self.delegate.textRanges[0].length).to(equal(0))
    }

    func test_paste_whenDelegateDoesNotAllowTextChanges_sendsNoEvents() {
        delegate.shouldAllowChangeText = false
        try! subject.startEditing()
        recorder.erase()
        try! subject.paste(text: "turtle magic")

        expect(self.recorder.recordedEvents).to(equal([]))
    }

    func test_paste_whenNoDelegate_sendsControlEvents() {
        try! subject.startEditing()
        subject.delegate = nil
        recorder.erase()
        try! subject.paste(text: "turtle magic")

        // One `.editingChanged` event for each letter typed.
        expect(self.recorder.recordedEvents).to(equal([
            .editingChanged,
            .allEditingEvents
        ]))
    }

    func test_backspace_deletesTheLastCharacter() {
        try! subject.startEditing()
        try! subject.type(text: "turtle magic")
        delegate.resetState()

        try! subject.backspace()

        expect(self.subject.text).to(equal("turtle magi"))
    }

    func test_backspace_sendsControlEvents() {
        try! subject.startEditing()
        try! subject.type(text: "turtle magic")
        delegate.resetState()
        recorder.erase()

        try! subject.backspace()

        expect(self.recorder.recordedEvents).to(equal([
            .editingChanged,
            .allEditingEvents
        ]))
    }

    func test_backspace_whenNotFirstResponder_raisesException() {
        expect { try self.subject.backspace() }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "Could not edit UITextField: Must start editing the text field before backspaces can be performed.", userInfo: nil, closure: nil)
        )
    }

    func test_backspace_whenDelegateAllowsTextChanges_callsDelegateMethodsAppropriately() {
        delegate.shouldAllowChangeText = true
        try! subject.startEditing()
        try! subject.type(text: "turtle magic")

        delegate.resetState()

        try! subject.backspace()

        expect(self.delegate.textChanges).to(equal([""]))
        expect(self.delegate.textRanges.count).to(equal(1))
        expect(self.delegate.textRanges[0].location).to(equal(11))
        expect(self.delegate.textRanges[0].length).to(equal(1))
    }

    func test_backspace_whenDelegateDoesNotAllowTextChanges_callsDelegateMethodsAppropriately() {
        try! subject.startEditing()
        try! subject.type(text: "turtle magic")

        delegate.resetState()

        delegate.shouldAllowChangeText = false
        try! subject.backspace()

        expect(self.delegate.textChanges).to(equal([]))
        expect(self.delegate.textRanges.count).to(equal(1))
        expect(self.delegate.textRanges[0].location).to(equal(11))
        expect(self.delegate.textRanges[0].length).to(equal(1))
        expect(self.subject.text).to(equal("turtle magic"))
    }

    func test_backspace_whenNoDelegate_deletesTheLastCharacter() {
        try! subject.startEditing()
        try! subject.type(text: "turtle magic")

        subject.delegate = nil

        try! subject.backspace()

        expect(self.subject.text).to(equal("turtle magi"))
    }

    func test_backspace_whenNoDelegate_sendsControlEvents() {
        try! subject.startEditing()
        try! subject.type(text: "turtle magic")
        recorder.erase()

        subject.delegate = nil

        try! subject.backspace()

        expect(self.recorder.recordedEvents).to(equal([
            .editingChanged,
            .allEditingEvents
        ]))
    }

    func test_backspace_whenNoTextInTextField_doesNothing() {
        try! subject.startEditing()

        delegate.resetState()

        try! subject.backspace()

        expect(self.subject.text).to(equal(""))
        expect(self.delegate.textChanges).to(equal([""]))
        expect(self.delegate.textRanges.count).to(equal(1))
        expect(self.delegate.textRanges[0].location).to(equal(0))
        expect(self.delegate.textRanges[0].length).to(equal(0))
    }

    func test_backspaceAll_deletesAllTextInTheField() {
        try! subject.startEditing()
        try! subject.type(text: "turtle magic")
        delegate.resetState()

        try! subject.backspaceAll()

        expect(self.subject.text).to(equal(""))
    }

    func test_backspaceAll_sendsControlEvents() {
        try! subject.startEditing()
        try! subject.type(text: "tur")
        delegate.resetState()
        recorder.erase()

        try! subject.backspaceAll()

        expect(self.recorder.recordedEvents).to(equal([
            .editingChanged,
            .allEditingEvents,
            .editingChanged,
            .allEditingEvents,
            .editingChanged,
            .allEditingEvents
            ]))
    }

    func test_backspaceAll_whenNotFirstResponder_raisesException() {
        expect { try self.subject.backspaceAll() }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "Could not edit UITextField: Must start editing the text field before backspaces can be performed.", userInfo: nil, closure: nil)
        )
    }

    func test_backspaceAll_whenDelegateAllowsTextChanges_callsDelegateMethodsAppropriately() {
        delegate.shouldAllowChangeText = true
        try! subject.startEditing()
        try! subject.type(text: "turtle")

        delegate.resetState()

        try! subject.backspaceAll()

        expect(self.delegate.textChanges).to(equal(["","","","","",""]))
        expect(self.delegate.textRanges.count).to(equal(6))
        expect(self.delegate.textRanges[0].location).to(equal(5))
        expect(self.delegate.textRanges[0].length).to(equal(1))
    }

    func test_backspaceAll_whenDelegateDoesNotAllowTextChanges_callsDelegateMethodsAppropriately() {
        try! subject.startEditing()
        try! subject.type(text: "turtle magic")

        delegate.resetState()

        delegate.shouldAllowChangeText = false
        try! subject.backspaceAll()

        expect(self.delegate.textChanges).to(equal([]))
        expect(self.delegate.textRanges.count).to(equal(12))
        expect(self.delegate.textRanges[0].location).to(equal(11))
        expect(self.delegate.textRanges[0].length).to(equal(1))
        expect(self.subject.text).to(equal("turtle magic"))
    }

    func test_backspaceAll_whenNoDelegate_deletesEveryCharacter() {
        try! subject.startEditing()
        try! subject.type(text: "turtle magic")

        subject.delegate = nil

        try! subject.backspaceAll()

        expect(self.subject.text).to(equal(""))
    }

    func test_backspaceAll_whenNoDelegate_sendsControlEvents() {
        try! subject.startEditing()
        try! subject.type(text: "tur")
        recorder.erase()

        subject.delegate = nil

        try! subject.backspaceAll()

        expect(self.recorder.recordedEvents).to(equal([
            .editingChanged,
            .allEditingEvents,
            .editingChanged,
            .allEditingEvents,
            .editingChanged,
            .allEditingEvents
            ]))
    }

    func test_backspaceAll_whenNoTextInTextField_doesNothing() {
        try! subject.startEditing()

        delegate.resetState()

        try! subject.backspaceAll()

        expect(self.subject.text).to(equal(""))
        expect(self.delegate.textChanges).to(equal([]))
        expect(self.delegate.textRanges.count).to(equal(0))
    }

    func test_clearText_whenTextFieldDisplaysClearButtonAlways_clearsTextWhetherEditingFieldOrNot() {
        subject.clearButtonMode = .always
        try! subject.enter(text: "turtle magic")

        try! subject.clearText() // Without trying to edit first

        expect(self.subject.text).to(equal(""))
        expect(self.delegate.didCallShouldClear).to(beTrue())

        delegate.resetState()

        try! subject.startEditing()
        try! subject.type(text: "turtle magic")
        try! subject.clearText() // While in edit mode

        expect(self.subject.text).to(equal(""))
        expect(self.delegate.didCallShouldClear).to(beTrue())
    }

    func test_clearText_whenTextFieldDisplaysClearButtonNever_raisesException() {
        subject.clearButtonMode = .never
        try! subject.enter(text: "turtle magic")

        // Without trying to edit first
        expect { try self.subject.clearText() }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "Could not clear text from UITextField: Clear button is never displayed.", userInfo: nil, closure: nil)
        )

        expect(self.subject.text).to(equal("turtle magic"))
        expect(self.delegate.didCallShouldClear).to(beFalse())

        delegate.resetState()

        try! subject.startEditing()
        try! subject.type(text: "++")

        // While in edit mode
        expect { try self.subject.clearText() }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "Could not clear text from UITextField: Clear button is never displayed.", userInfo: nil, closure: nil)
        )

        expect(self.subject.text).to(equal("turtle magic++"))
        expect(self.delegate.didCallShouldClear).to(beFalse())
    }

    func test_clearText_whenTextFieldDisplaysClearButtonOnlyDuringEditing() {
        subject.clearButtonMode = .whileEditing
        try! subject.enter(text: "turtle magic")

        // Without trying to edit first
        expect { try self.subject.clearText() }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "Could not clear text from UITextField: Clear button is hidden when not editing.", userInfo: nil, closure: nil)
        )

        expect(self.subject.text).to(equal("turtle magic"))
        expect(self.delegate.didCallShouldClear).to(beFalse())

        delegate.resetState()

        try! subject.startEditing()
        try! subject.type(text: "++")

        // While in edit mode
        try! subject.clearText()

        expect(self.subject.text).to(equal(""))
        expect(self.delegate.didCallShouldClear).to(beTrue())
    }

    func test_clearText_whenTextFieldDisplaysClearButtonUnlessEditing() {
        subject.clearButtonMode = .unlessEditing
        try! subject.enter(text: "turtle magic")

        // Without trying to edit first
        try! subject.clearText()

        expect(self.subject.text).to(equal(""))
        expect(self.delegate.didCallShouldClear).to(beTrue())

        delegate.resetState()

        try! subject.startEditing()
        try! subject.type(text: "++")

        // While in edit mode
        expect { try self.subject.clearText() }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "Could not clear text from UITextField: Clear button is hidden when editing.", userInfo: nil, closure: nil)
        )

        expect(self.subject.text).to(equal("++"))
        expect(self.delegate.didCallShouldClear).to(beFalse())
    }

    func test_clearText_whenTextFieldIsHidden_raisesException() {
        subject.isHidden = true
        subject.clearButtonMode = .always

        expect { try self.subject.clearText() }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "UITextField unavailable for editing: Text field is not visible.", userInfo: nil, closure: nil)
        )
        expect(self.delegate.didCallShouldClear).to(beFalse())
    }

    func test_clearText_whenTextFieldIsNotEnabled_raisesException() {
        subject.isEnabled = false
        subject.clearButtonMode = .always

        expect { try self.subject.clearText() }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "UITextField unavailable for editing: Text field is not enabled.", userInfo: nil, closure: nil)
        )
        expect(self.delegate.didCallShouldClear).to(beFalse())
    }

    func test_clearText_whenItWorks_sendsControlEvents() {
        subject.clearButtonMode = .always
        try! subject.enter(text: "turtle magic")
        recorder.erase()
        try! subject.clearText()

        expect(self.recorder.recordedEvents).to(equal([
            .editingChanged,
            .allEditingEvents
        ]))
    }

    func test_clearText_whenDelegateDoesNotAllowClearing_doesNotClear() {
        subject.clearButtonMode = .always
        try! subject.enter(text: "turtle magic")
        delegate.shouldAllowClearText = false
        recorder.erase()
        try! subject.clearText()

        expect(self.subject.text).to(equal("turtle magic"))
        expect(self.delegate.didCallShouldClear).to(beTrue())
        expect(self.recorder.recordedEvents).to(equal([]))
    }

    func test_enter_convenienceMethod_startsEditingATextFieldTypesTextAndStopsEditingAllInOneAction() {
        try! subject.enter(text: "turtle magic")

        expect(self.subject.text).to(equal("turtle magic"))
        expect(self.delegate.textChanges).to(equal(["t", "u", "r", "t", "l", "e", " ", "m", "a", "g", "i", "c"]))
        expect(self.delegate.textRanges.count).to(equal(12))
        expect(self.delegate.textRanges[0].location).to(equal(0))
        expect(self.delegate.textRanges[0].length).to(equal(0))
        expect(self.delegate.textRanges[9].location).to(equal(9))
        expect(self.delegate.textRanges[9].length).to(equal(0))
        expect(self.delegate.didCallShouldBeginEditing).to(beTrue())
        expect(self.delegate.didCallDidBeginEditing).to(beTrue())
        expect(self.delegate.didCallShouldEndEditing).to(beTrue())
        expect(self.delegate.didCallDidEndEditing).to(beTrue())
        expect(self.subject.isFirstResponder).to(beFalse())
    }

    func test_enter_convenienceMethod_sendsControlEvents() {
        try! subject.enter(text: "four")

        expect(self.recorder.recordedEvents).to(equal([
            .touchDown,
            .allTouchEvents,
            .editingDidBegin,
            .allEditingEvents,
            .editingChanged,
            .allEditingEvents,
            .editingChanged,
            .allEditingEvents,
            .editingChanged,
            .allEditingEvents,
            .editingChanged,
            .allEditingEvents,
            .editingDidEnd,
            .allEditingEvents
        ]))
    }

    func test_whenTextFieldClearsOnEntry_whenDelegateAllowsClearing_clearsTextWhenEditingBegins() {
        subject.clearsOnBeginEditing = true
        delegate.shouldAllowClearText = true
        try! subject.enter(text: "turtle magic")
        expect(self.subject.text).to(equal("turtle magic"))

        try! subject.startEditing()
        expect(self.subject.text).to(equal(""))
    }

    func test_whenTextFieldClearsOnEntry_whenDelegateDoesNotAllowClearing_doesNotClearTextWhenEditingBegins() {
        subject.clearsOnBeginEditing = true
        delegate.shouldAllowClearText = false
        try! subject.enter(text: "turtle magic")
        expect(self.subject.text).to(equal("turtle magic"))

        try! subject.startEditing()
        expect(self.subject.text).to(equal("turtle magic"))
    }

    fileprivate class BarebonesTextFieldDelegate: NSObject, UITextFieldDelegate {
        override init() {}
    } // implements none of the methods

    func test_whenUsingDelegateWithNoImplementations_performsAsExpected() {
        let textField = UITextField()
        let minimallyImplementedDelegate = BarebonesTextFieldDelegate()
        textField.delegate = minimallyImplementedDelegate
        try! Test.embedViewIntoMainApplicationWindow(textField)

        try! textField.enter(text: "turtle magic")
        expect(textField.text).to(equal("turtle magic"))
        try! textField.startEditing()
        try!textField.backspace()
        expect(textField.text).to(equal("turtle magi"))
        try! textField.paste(text: "c woo")
        expect(textField.text).to(equal("turtle magic woo"))
        try! textField.stopEditing()
    }

    func test_whenUserInteractionIsDisabled_doesAbsolutelyNothingAndRaisesException() {
        subject.isUserInteractionEnabled = false
        expect { try self.subject.enter(text: "turtle magic") }.to(
            raiseException(named: "Fleet.TextFieldError", reason: "UITextField unavailable for editing: View does not allow user interaction.", userInfo: nil, closure: nil)
        )

        expect(self.subject.text).to(equal(""))
        expect(self.delegate.textChanges).to(equal([]))
        expect(self.delegate.textRanges.count).to(equal(0))
        expect(self.delegate.didCallShouldBeginEditing).to(beFalse())
        expect(self.delegate.didCallDidBeginEditing).to(beFalse())
        expect(self.delegate.didCallShouldEndEditing).to(beFalse())
        expect(self.delegate.didCallDidEndEditing).to(beFalse())
        expect(self.subject.isFirstResponder).to(beFalse())
    }
}
