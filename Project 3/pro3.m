% Data & Computer communications Project 3 - MN22L

% open DATA file and read values
filename = 'DATA_GOOD';
dataGood = readlines(filename);
dataGood = double(dataGood);

% open ACK file and read values
filename = 'ACK_GOOD';
ackGood = readlines(filename);
ackGood = double(ackGood);

% initialize variables
transmissionDelay = 1;
propogationDelay = 3;
ackDelay = 0;
timeout = 7;
windowSize = 7;
time = 0;
windowStart = 0;
windowEnd = getwindowEnd(windowStart, windowSize);
sequenceNumber = 0;
timeEnd = 100;

% queue to keep track of sender window frames
WQ = windowStart:windowEnd;
% status queue to track if frame is sent or not
WQStatus = zeros(1,length(WQ));
% queue to track when frame will be sent
WQSentTimes = zeros(1,length(WQ));
% queue to track when frame will be received
WQReceiveTimes = zeros(1,length(WQ));
% queue to track when frame timeouts
WQSentTimeouts = zeros(1,length(WQ));
% bool to track if sender is currently sending
dataBeingSent = false;
receiverSequence = 0;
% queue to keep track of ack frames
AQ = windowStart:windowEnd;
% status queue to track if ACK is sent or not
AQStatus = zeros(1,length(AQ));
% queue to track when ACK will be sent
AQSentTimes = zeros(1,length(AQ));
% queue to track when ACK will be received
AQReceiveTimes = zeros(1,length(AQ));

% Start looping
while(1)

    if time == 8
        disp("HERE");
    end

    % see if receiver received any frames
    for i = 1:length(WQReceiveTimes)
        % inital case
        if WQReceiveTimes(i) == time && time == 0 && ackGood(time+1) == 1
            % receiver sends ACK0
            receiverSequence = 0;
            AQReceiveTimes(i) = 0;
            AQStatus(i) = 1;
            break;
        end
        % general case
        if WQReceiveTimes(i) == time && time ~= 0
            % receiver received WQ(i)
            receivedFrame = WQ(i);
            %disp(getTimeString(time) + " ----- receivedFrame = "+ receivedFrame +" receiversequence = " + receiverSequence);
            if receivedFrame == receiverSequence
                % receiver sends ACK#receiverSequence+1
                receiverSequence = receiverSequence + 1;
                if ackGood(time+1) == 1
                    AQStatus(AQ == receiverSequence) = 1;
                    AQReceiveTimes(AQ == receiverSequence) = time + ackDelay + propogationDelay;
                else
                    AQStatus(AQ == receiverSequence) = 1;
                    % ACK is lost
                    AQReceiveTimes(AQ == receiverSequence) = 0;
                end
            else
                %disp(getTimeString(time) + " ----- receivedFrame = "+ receivedFrame +" receiversequence = " + receiverSequence);
                if ackGood(time+1) == 1
                    AQStatus(AQ == receiverSequence) = 1;
                    AQReceiveTimes(AQ == receiverSequence) = time + ackDelay + propogationDelay;
                else
                    AQStatus(AQ == receiverSequence) = 1;
                    % ACK is lost
                    AQReceiveTimes(AQ == receiverSequence) = 0;
                end

            end
            
            receiverOutput = getTimeString(time) + "receiver got frame " + receivedFrame + ", transmitting ACK" + receiverSequence + ", " + getTransmissionString(ackGood(time+1));
            disp(receiverOutput);
            break;
        end
    end

    % see if sender received any ACKs
    for i = 1:length(AQReceiveTimes)
        if time == AQReceiveTimes(i)
            % sender received ACK#receiverSequence
            receivedAQ = AQ(i);

            % slide window
            while(WQ(1) < receivedAQ)
                windowStart = receivedAQ;
                windowEnd = getwindowEnd(windowStart, windowSize);
                WQ = [WQ(2:length(WQ)) WQ(length(WQ))+1];
                WQSentTimes = [WQSentTimes(2:length(WQSentTimes)) 0];
                WQReceiveTimes = [WQReceiveTimes(2:length(WQReceiveTimes)) 0];
                WQSentTimeouts = [WQSentTimeouts(2:length(WQSentTimeouts)) 0];
            end
            
            while(AQ(1) <= receivedAQ)
                AQ = [AQ(2:length(AQ)) AQ(length(AQ))+1];
                AQReceiveTimes = [AQReceiveTimes(2:length(AQReceiveTimes)) 0];
            end

            senderOutput = getTimeString(time) + "sender got ACK" + receivedAQ + ", window " + getWindowString(windowStart, windowEnd);
            disp(senderOutput);
              
            break;
        end
    end

    % see if any sender frame timedout
    for i = 1:length(WQSentTimeouts)
        if WQSentTimeouts(i) == time && time ~= 0
            % frame i timed out
            %disp(getTimeString(time) + "frame " + WQ(i) + " timed out");
            sequenceNumber = WQ(i);
            for j = i:length(WQSentTimeouts)
                WQStatus(j) = 0;
                WQSentTimes(j) = 0;
                WQSentTimeouts(j) = 0;
                WQReceiveTimes(j) = 0;
            end
            break;
        end
    end


    % see if sender needs to complete sending a frame
    for i = 1:length(WQSentTimes)
        if WQSentTimes(i) == time && time ~=0
            % mark frame i sent
            WQStatus(i) = 1;
            dataBeingSent = false;
            sequenceNumber = sequenceNumber + 1;
            WQSentTimeouts(i) = time + timeout;
            break;
        end
    end

    % see if sender needs to send any frame
    for i = 1:length(WQ)
        if sequenceNumber == WQ(i) && WQStatus(i) ~= 1 && ~dataBeingSent
            % send frame i
            dataBeingSent = true;
            WQSentTimes(i) = time + transmissionDelay;
            if dataGood(time+1) == 1
                WQReceiveTimes(i) = time + transmissionDelay + propogationDelay;
            else
                % data frame will be lost
                WQReceiveTimes(i) = 0;
            end
            % print sending message
            senderOutput = getTimeString(time) + "sender window " + getWindowString(windowStart, windowEnd) + ", transmitting new frame " + WQ(i) + ", " + getTransmissionString(dataGood(time+1));
            disp(senderOutput);
            break;
        end
    end

    time = time + 1;
    
    if time == timeEnd 
        break;
    end

end

function windowEnd = getwindowEnd(windowStart, windowSize)
    windowEnd = windowStart + windowSize -1;
end

function transmissionString = getTransmissionString(transmissionStatus)
    if transmissionStatus == 1
        transmissionString = "good transmission ";
    else
        transmissionString = "bad transmission ";
    end
end

function timeString = getTimeString(time)
    timeString = "time " + time + ": ";
end

function windowString = getWindowString(windowStart, windowEnd)
    windowString = "[" + windowStart + ", " + windowEnd + "]";
end