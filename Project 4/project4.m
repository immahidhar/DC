% -----------------------------------------------------------------------------------------------------------------

% Data & Computer communications Project 4 - MN22L

% -----------------------------------------------------------------------------------------------------------------

% open test signal file and read values
filename = 'MAC_testdata1';
signalValues = readlines(filename);
signalValues = signalValues(signalValues ~= "");
signalValues = split(signalValues);
signalValues = double(signalValues);
amplitudes = NaN;
for i = 1:length(signalValues)
    amplitudes(i,1) = sqrt(signalValues(i,1).^2 + signalValues(i,2).^2);
end

amplitudes = amplitudes(10000:20000);
% plot signal amplitudes
tiledlayout(2,1);
nexttile;
plot(1:length(amplitudes),amplitudes);
grid on;
%hold on;

% constants
speedOfA = 18; % bits per usecond
packetSize = 1500 * 8; % bits
sampleTime = 4; % useconds

packetLengthOfA = round((packetSize/speedOfA)/sampleTime);
packetLengthOfA = round(packetLengthOfA - 0.1 * packetLengthOfA);

% thresholds defined manually
ackMin = 0.2;
ackMax = 0.35;
aMin = 0.4;

sampleValues = NaN;
aValue = 2;
ackValue = 1;
otherValue = 0;

% -----------------------------------------------------------------------------------------------------------------

% identify A samples based on thresholds
for i = 1:length(amplitudes)
    if(amplitudes(i) > aMin) 
        sampleValues(i) = aValue;
    %elseif(amplitudes(i) > ackMin && amplitudes(i) < ackMax)
    %    sampleValues(i) = ackValue;
    else
        sampleValues(i) = 0;
    end
end
% smooth out A samples
index = 1;
while index <= length(sampleValues)
    sampleValue = sampleValues(index);
    if(sampleValue == aValue)
        [packetEnd, sampleValues] = analyzePacketA(index, packetLengthOfA, aValue, sampleValues);
        index = packetEnd + 1;
    else
        index = index + 1;
    end
end

nexttile;
plot(1:length(sampleValues),sampleValues);
%hold off;

%count A packets
numOfAPackets = 0;
lastSample = NaN;
nextFewSamples = 5;
for i = 1:length(sampleValues)
    if sampleValues(i) == 0 && lastSample == aValue
        zeroValueFreq = sum(sampleValues(i:i+nextFewSamples)==0);
        aValueFreq = sum(sampleValues(i:i+nextFewSamples)==aValue);
        %disp([zeroValueFreq, aValueFreq]);
        if zeroValueFreq > aValueFreq
            numOfAPackets = numOfAPackets +1;
        end
    end
    lastSample = sampleValues(i);
end
disp("Total number of packets from node A : " + numOfAPackets);

% -----------------------------functions---------------------------------------------------------------------------

function [packetEnd, sampleValues] = analyzePacketA(packetStart, packetLengthOfA, aValue, sampleValues)
    packetEnd = packetStart + packetLengthOfA;
    
    if packetEnd <= length(sampleValues)
        packetSampleValues = sampleValues(packetStart:packetEnd);
        aValueFreq = sum(packetSampleValues==aValue);
        %disp(aValueFreq);
        if aValueFreq >= 0.85 * packetLengthOfA
            for i=1:length(packetSampleValues)
                if packetSampleValues(i) ~= aValue
                    packetSampleValues(i) = aValue;
                end
                sampleValues(packetStart:packetEnd) = packetSampleValues;
            end
        else
            for i=1:length(packetSampleValues)
                if packetSampleValues(i) ~= 0
                    packetSampleValues(i) = 0;
                end
                sampleValues(packetStart:packetEnd) = packetSampleValues;
            end
            packetEnd = packetStart + 1;
        
        end
    else
        packetEnd = packetStart + 1;
    end
    %disp([packetStart, packetEnd, packetEnd-packetStart]);
end

% -----------------------------------------------------------------------------------------------------------------
