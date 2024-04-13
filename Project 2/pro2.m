% Data & Computer communications Project 2 - MN22L

% open test signal file and read values
filename = 'proj1_testsignal2';
signalValues = readlines(filename);
signalValues = double(signalValues);
% open noise signal file and read values
filename = 'proj2_noisesignal2';
noiseValues = readlines(filename);
noiseValues = double(noiseValues);
% form corrupted signal
signalValues = signalValues + noiseValues;

normalizedSignal = signalValues;

% get time values for plot
numOfValues = length(signalValues);
time = 1:numOfValues;

% plot signal
plot(time, signalValues);
title('Signal');

% noise threshold
noiseAmps = signalValues(1:10000);
mn = mean(noiseAmps);
sd = std(noiseAmps);
threshold = mn*4 + sd*8;
disp("noise threshold = " + threshold);

% iterate through samples to find symbol start point
flag = false;
symbolStart = 0;
for i = 1:numOfValues
    if signalValues(i) > threshold
        normalizedSignal(i) = 1;
        if flag == false
            symbolStart = i;
            disp("symbol start index = "+ symbolStart);
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
bytesEndIndex = signalLength;
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
            disp("Symbol end index = " + (symbolStart+bytesEndIndex-1));
            flag = true;
            break;
        end
    end
    offset = offset+100;
end

% Get only the data bytes array now by removing preamble
preamblesize = 8;
bytes = bytes(preamblesize+1:bytesEndIndex-1);

% Check for errors - hamming(7,4) and correct any single bit errors
offset = 1;
for i=1:length(bytes)/7
    bytes(offset:offset+6) = ecc_hamming(bytes(offset:offset+6));
    offset = offset + 7;
end

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
disp("Output :");
disp(string);

function correct_bytes = ecc_hamming(error_bytes) 
    len = length(error_bytes);
    if len ~= 7
        disp("bytes length is not 7");
        return;
    end
    H = [1 0 1; 1 1 1; 1 1 0; 0 1 1; 1 0 0; 0 1 0; 0 0 1];
    S = error_bytes * H;
    S = rem(S,2);
    num = bit2int(S', 3, true);
    Hnum = bit2int(H', 3, true);
    if num ~= 0 
        err_indx = find(Hnum == num);
        error_bytes(err_indx) = xor(error_bytes(err_indx), 1); 
    end
    correct_bytes = error_bytes;
end