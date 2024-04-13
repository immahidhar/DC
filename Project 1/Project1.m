% Data & Computer communications Project 1 - MN22L
% 
% References :
% https://www.mathworks.com/help/matlab/ref/readlines.html
% https://www.mathworks.com/help/matlab/ref/double.ismember.html
% https://www.mathworks.com/help/matlab/ref/switch.html
% https://www.mathworks.com/help/matlab/ref/reshape.html
% https://www.mathworks.com/help/comm/ref/bit2int.html
% https://www.mathworks.com/help/matlab/ref/char.html

% open test signal file and read values
filename = 'proj1_testsignal1';
signalValues = readlines(filename);
signalValues = double(signalValues);
normalizedSignal = signalValues;

% get time values for plot
numOfValues = length(signalValues);
time = 1:numOfValues;

% plot signal
plot(time, signalValues);
title('Signal')

% noise threshold
noiseAmps = signalValues(1:10000);
mn = mean(noiseAmps);
sd = std(noiseAmps);
threshold = mn*8 + sd*16;

% iterate through samples to find symbol start point
flag = false;
symbolStart = 0;
for i = 1:numOfValues
    if signalValues(i) > threshold
        normalizedSignal(i) = 1;
        if flag == false
            symbolStart = i;
            flag = true;
        end
    else
        normalizedSignal(i) = 0;
    end
end

% iterate from symbolStart and read bytes
normalizedSignal = normalizedSignal(symbolStart:numOfValues);
signalLength = length(normalizedSignal);
symbolLength = 100;
offset = 1;
flag = false;
bytes = NaN;
bytesEndIndex = 0;
for i = 1:signalLength/symbolLength
    symbol = normalizedSignal(offset:offset+99);
    symbolBegining = symbol(1:30);
    symbolMiddle = symbol(30:70);
    if ismember(1, symbolBegining)
        bytes(i) = 0;
    elseif ismember(1, symbolMiddle)
        bytes(i) = 1;
    else
        bytes(i) = NaN;
        if flag == false
            bytesEndIndex = i;
            flag = true;
            break;
        end
    end
    offset = offset+100;
end

% Get only the data bytes array now by removing preamble
bytes = bytes(9:bytesEndIndex-1);

% Get the final set of bytes by dropping parity bytes
finalBytes = NaN;
counter = 1;
finalBytesIndex = 1;
for index=1:length(bytes)
    switch counter
        case {1,2,3,4}
            finalBytes(finalBytesIndex) = bytes(index);
            finalBytesIndex = finalBytesIndex+1;
            counter = counter+1;
        case {5,6}
            counter = counter+1;
        case 7
            counter = 1;
    end
end

% Now get the output
bytesMatrix = reshape(finalBytes, [8,length(finalBytes)/8]);
decimalMatrix = bit2int(bytesMatrix,8,true);
string = char(decimalMatrix);
disp(string);