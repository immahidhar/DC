# Data & Computer communications Project 3 - MN22L

import copy

# flag to see debug statements in output. TODO : this should be false before submission
debug = False

# open DATA_GOOD file and read values
fileName = "DATA_GOOD_2"
file = open(fileName, "r")
dataGood = list()
for data in file:
    if data is not None and data != "" and data != "\n":
        dataGood.append(int(data))

# open ACK_GOOD file and read values
fileName = "ACK_GOOD_2"
file = open(fileName, "r")
ackGood = list()
for data in file:
    if data is not None and data != "" and data != "\n":
        ackGood.append(int(data))


def getTimeString(t):
    return "time " + t.__str__() + ": "


def getWindowString(start, end):
    return "[" + start.__str__() + ", " + end.__str__() + "]"


def getTransmissionAge(age):
    if age == "new":
        return ", transmitting " + age
    else:
        return ", retransmitting " + age


def getTransmissionString(good):
    if good == 1:
        return ", good transmission "
    else:
        return ", bad transmission "


# initialize variables
transmissionDelay = 1
propagationDelay = 3
ackDelay = 0
timeout = 7
windowSize = 7
time = 0


class Frame:
    def __init__(self, sequenceNumber, sent, sentTime, received, receiveTime, timeoutTime, age):
        self.sequenceNumber = sequenceNumber
        self.sent = sent
        self.sentTime = sentTime
        self.received = received
        self.receiveTime = receiveTime
        self.timeoutTime = timeoutTime
        self.age = age

    def __str__(self):
        return f"#{self.sequenceNumber}, sent = {self.sent}, sentTime = {self.sentTime}, received = {self.received}, " \
               f"receiveTime = {self.receiveTime}, timeoutTime = {self.timeoutTime}, {self.age}"

    def __sent__(self):
        self.sent = True
        self.timeoutTime = time + timeout

    def __prepare__for_re_transmission__(self):
        self.sent = False
        self.sentTime = None
        self.received = False
        self.receiveTime = None
        self.timeoutTime = None
        self.age = "old"


class Window:
    def __init__(self, frameList, size):
        self.frames = frameList
        self.size = size

    def __str__(self):
        ps = "[\n "
        for f in self.frames:
            ps += str(f)
            ps += "\n "
        ps += "]"
        return ps

    def getWindowStart(self):
        if self.frames is not None and len(self.frames) > 0:
            for frame in self.frames:
                return frame.sequenceNumber
        else:
            return 0

    def getWindowEnd(self):
        return self.getWindowStart() + self.size - 1

    # replace a given frame in the window
    def __replace__(self, oldF, newF):
        for index in range(len(self.frames)):
            if self.frames[index] == oldF:
                self.frames[index] = newF
                break

    # slide window till the given sequenceNumber
    def __slide__(self, sequenceNumber):
        if debug:
            print("---- sliding window ----")
        # delete frames till sequenceNumber passed
        self.frames = [f for f in self.frames if not f.sequenceNumber < sequenceNumber]
        # add new frames till windowSize is reached
        if len(self.frames) != self.size:
            numberOfNewFrames = self.size - len(self.frames)
            latestSequenceNumber = 0
            for f in self.frames:
                latestSequenceNumber = f.sequenceNumber
            for j in range(numberOfNewFrames):
                latestSequenceNumber = latestSequenceNumber + 1
                newF = Frame(latestSequenceNumber, False, None, False, None, None, "new")
                self.frames.append(newF)


# create initial window and frames
frames = list()
for i in range(windowSize):
    newFrame = Frame(i, False, None, False, None, None, "new")
    frames.append(newFrame)
initialWindow = Window(frames, windowSize)
# create a framesList - this is where sent frames will be stored
framesList = list()
# create an ACK list as well - this is where sent ACKs will be stored
ackList = list()


class Sender:
    def __init__(self, senderWindow, sequenceNumber, busy, counter):
        self.window = senderWindow
        self.sequenceNumber = sequenceNumber
        self.busy = busy
        self.counter = counter

    def __str__(self):
        return f"*** SENDER = \n window = {self.window}\t, senderSequenceNumber = {self.sequenceNumber}\t," \
               f" busy = {self.busy} ***"

    def checkWindowForTimeouts(self):
        for frame in self.window.frames:
            # if sender needs to retransmit, prepare for retransmit all sent frames in window
            if frame.timeoutTime is not None and frame.timeoutTime == time:
                if debug:
                    print("---- preparing retransmit; frame " + str(frame.sequenceNumber) + " timed out ----")
                frameCopy = copy.deepcopy(frame)
                frameCopy.__prepare__for_re_transmission__()
                self.window.__replace__(frame, frameCopy)

    # complete sending a frame if any, based on frame.sentTime
    def completeSending(self):
        for frame in self.window.frames:
            if frame.sentTime is not None and frame.sentTime == time and self.busy:
                # consider current frame sent - this will set the timeout for frame i.e. timer
                frame.__sent__()
                self.busy = False
                if debug:
                    print("---- sender.busy = " + str(self.busy) + " ----")
                # increment sender#SequenceNumber
                if self.sequenceNumber <= self.window.getWindowEnd() + 1:
                    self.sequenceNumber = frame.sequenceNumber + 1
                    if debug:
                        print("---- sender.sequenceNumber = " + str(self.sequenceNumber) + " ----")
                break
        # make sure sender status is correct
        self.ensureCorrectStatus()
        # make sure sequence number is correct
        self.ensureCorrectSequenceNumber()

    def ensureCorrectStatus(self):
        if self.busy:
            # check if none of the frames in window are sent, but status is busy
            flag = False
            for frame in self.window.frames:
                if frame.sentTime is not None:
                    flag = True
                    break
            # window may have been slided and none of the frames are sent, but status is busy
            if not flag:
                self.busy = False
                if debug:
                    print("---- sender status reset ----")
                    print("---- sender.busy = " + str(self.busy) + " ----")
            # check if all sentTime are less than current times, but status is busy
            flag = False
            for frame in self.window.frames:
                if frame.sentTime is not None and frame.sentTime > time:
                    flag = True
            # window may have been slided and one of the sentTime that needs to completed is missed, but status is busy
            if not flag:
                self.busy = False
                if debug:
                    print("---- sender status reset ----")
                    print("---- sender.busy = " + str(self.busy) + " ----")

    def ensureCorrectSequenceNumber(self):
        # see if we need to reset senderSequenceNumber
        if not self.window.getWindowStart() <= self.sequenceNumber <= self.window.getWindowEnd():
            # if sequence number out of window
            for frame in self.window.frames:
                # if there is a new unsent frame, set it as sequence number
                if not frame.sent and frame.age == "new":
                    self.sequenceNumber = frame.sequenceNumber
                    if debug:
                        print("---- sender.sequenceNumber = " + str(self.sequenceNumber) + " ----")
                    break

    def sendTimedOutFrameIfAny(self):
        if not self.busy:
            for frame in self.window.frames:
                if not frame.sent and frame.age == "old" and frame.timeoutTime is None:
                    self.sendFrame(frame)
                    break

    # send the next frame to be sent from window if any
    def sendFrameIfAny(self):
        # see if we need to complete sending any frame being sent
        self.completeSending()
        # check for timeouts and prepare for retransmit
        self.checkWindowForTimeouts()
        # send timed out frames if sender is not busy
        self.sendTimedOutFrameIfAny()
        # if sequenceNumber is within window, send the frame#sequenceNumber if sender is not busy
        if not self.busy and self.window.getWindowStart() <= self.sequenceNumber <= self.window.getWindowEnd():
            for frame in self.window.frames:
                if not frame.sent and frame.sequenceNumber == self.sequenceNumber:
                    self.sendFrame(frame)
                    break

    # send given frame
    def sendFrame(self, frame):
        self.busy = True
        if debug:
            print("---- sender.busy = " + str(self.busy) + " ----")
        frame.sentTime = time + transmissionDelay
        if dataGood.__getitem__(self.counter) == 0:
            # data will be lost
            frame.receiveTime = None
        else:
            frame.receiveTime = time + transmissionDelay + propagationDelay
            # send the frame
            framesList.append(frame)
        # print send message
        senderSendString = getTimeString(time) + "sender window " + getWindowString(self.window.getWindowStart(),
                                                                                    self.window.getWindowEnd()) + \
                           getTransmissionAge(frame.age) + " frame " + str(frame.sequenceNumber) \
                           + getTransmissionString(dataGood.__getitem__(self.counter))
        print(senderSendString)
        self.counter = self.counter + 1

    # sender receives an ack
    def receiveACKIfAny(self):
        for ack in ackList:
            if not ack.received and ack.receiveTime is not None and ack.receiveTime == time:
                # mark ack received
                ack.received = True
                # ignore if ack is not in window, else slide window
                if self.window.getWindowStart() <= ack.sequenceNumber <= self.window.getWindowEnd():
                    # slide window
                    if debug:
                        print("---- " + str(self.window) + " ----")
                    self.window.__slide__(ack.sequenceNumber)
                    if debug:
                        print("---- " + str(self.window) + " ----")
                senderReceiveString = getTimeString(time) + "sender got ACK" + str(ack.sequenceNumber) + ", window " \
                                      + getWindowString(self.window.getWindowStart(), self.window.getWindowEnd())
                print(senderReceiveString)


class Receiver:
    def __init__(self, sequenceNumber, counter):
        self.sequenceNumber = sequenceNumber
        self.counter = counter

    def __str__(self):
        return f"*** RECEIVER = ACK#{self.sequenceNumber} ***"

    def sendACK(self):
        if ackGood.__getitem__(self.counter) == 1:
            # create an ACK frame
            ack = Frame(self.sequenceNumber, True, None, False, time + ackDelay + propagationDelay, None, None)
            # send the ack
            ackList.append(ack)

    def receiveFrameIfAny(self):
        for frame in framesList:
            if frame.receiveTime is not None and not frame.received and frame.receiveTime == time:
                # frame#sequenceNumber is received
                frame.received = True
                # increment receiver sequence number if this is the frame receiver is expecting
                if frame.sequenceNumber == self.sequenceNumber:
                    self.sequenceNumber = self.sequenceNumber + 1
                # send ACK back
                self.sendACK()
                receiverString = getTimeString(time) + "receiver got frame " + str(frame.sequenceNumber) \
                                 + ", transmitting ACK" + str(self.sequenceNumber) \
                                 + getTransmissionString(ackGood.__getitem__(self.counter))
                print(receiverString)
                self.counter = self.counter + 1
                break


# create a sender
sender = Sender(initialWindow, 0, False, 0)
# create a receiver
receiver = Receiver(0, 0)

# start looping and processing
while sender.counter < dataGood.__len__() and receiver.counter < ackGood.__len__():

    if debug:
        print("\ntime = " + str(time))
        print(sender.__str__())
        print(receiver.__str__())

    # initial case send ACK0
    if time == 0:
        ack0 = Frame(0, True, None, False, 0, None, None)
        # send ACK0
        ackList.append(ack0)

    # debugging purpose
    if debug and time == 68:
        print("HERE")

    # see if receiver received any frames
    receiver.receiveFrameIfAny()

    # see if sender received any ACKs
    sender.receiveACKIfAny()

    # see if sender needs to send any frame
    sender.sendFrameIfAny()

    # increment time
    time = time + 1
