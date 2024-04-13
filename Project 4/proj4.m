% -------------------------------------------------------------------------

% Data & Computer communications Project 4 - MN22L

% -------------------------------------------------------------------------

% open test signal file and read values
filename = 'MAC_testdata2';
signalValues = readlines(filename);
signalValues = signalValues(signalValues ~= "");
signalValues = split(signalValues);
signalValues = double(signalValues);
amplitudes = NaN;
for i = 1:length(signalValues)
    amplitudes(i,1) = sqrt(signalValues(i,1).^2 + signalValues(i,2).^2);
end
%amplitudes = amplitudes(10000:20000);

% -------------------------------------------------------------------------

% plot signal amplitudes
%tiledlayout(2,1);
%nexttile;
plot(1:length(amplitudes),amplitudes);
grid on;
%hold on;

% constants
speedOfA = 18; % Mega bits per usecond
packetSize = 1500 * 8; % bits
sampleTime = 4; % Micro seconds

packetLengthOfA = round((packetSize/speedOfA)/sampleTime);
%packetLengthOfA = round(packetLengthOfA - 0.03 * packetLengthOfA);

% thresholds defined manually
ackMin = 0.2;
ackMax = 0.35;
aMin = 0.4;
peakPercentofA = 0.93;
peakPercentOfACK = 0.1;
nextFewSamplesForACK = 15;

% -------------------------------------------------------------------------

sampleValues = amplitudes;
packetEndsOfA = NaN;
packetEndOfAIndex = 1;
packetEndsOfAWithAcks = NaN;
packetEndsOfAWithAcksIndex = 1;
numOfAPackets = 0;
numOfACKPacketsForA = 0;
numOfACKPacketsForFreshA = 0;

% identify packet A samples based on aMin
index = 1;
while index <= length(sampleValues)
    sampleValue = sampleValues(index);
    if(sampleValue >= aMin)
        [packetEnd, sampleValues] = analyzePacketForASample(index, ...
            packetLengthOfA, aMin, sampleValues, peakPercentofA);
        if packetEnd ~= index
            % confirmed that there is an A packet here
            numOfAPackets = numOfAPackets + 1;
            packetEndsOfA(packetEndOfAIndex) = packetEnd;
            packetEndOfAIndex = packetEndOfAIndex + 1;
            % identify ACKs after the A packet
            ackPresent = checkForAck(packetEnd, nextFewSamplesForACK, ...
                ackMin, ackMax, sampleValues, peakPercentOfACK);
            if ackPresent
                numOfACKPacketsForA = numOfACKPacketsForA + 1;
                packetEndsOfAWithAcks(packetEndsOfAWithAcksIndex)=packetEnd;
                packetEndsOfAWithAcksIndex = packetEndsOfAWithAcksIndex+1;
            end
        end
        index = packetEnd + 1;
    else
        index = index + 1;
    end
end

% calculate ACKs for fresh packets only
for i=1:length(packetEndsOfA)
    % if there is an ack for a packet, 
    % the packet before should also have an ACK
    if ismember(packetEndsOfA(i), packetEndsOfAWithAcks)
        if i~=1 && ismember(packetEndsOfA(i-1), packetEndsOfAWithAcks)
            numOfACKPacketsForFreshA = numOfACKPacketsForFreshA + 1;
        end
    end
end

disp("Total number of packets from node A : " + numOfAPackets);
disp("Total number of packets with ACK from node A : " ...
    + numOfACKPacketsForA);
% number of packets ACKed, must be fresh pacekts for A
disp("Total number of fresh packets from node A : " ...
    + numOfACKPacketsForA);
disp("Total number of fresh packets with ACK from node A : " ...
    + numOfACKPacketsForFreshA);

% -----------------------------functions-----------------------------------

function [packetEnd, sampleValues] = analyzePacketForASample(packetStart, ...
    packetLengthOfA, aMin, sampleValues, peakPercent)

    packetEnd = packetStart + packetLengthOfA;
    if packetEnd <= length(sampleValues)
        packetSampleValues = sampleValues(packetStart:packetEnd);
        aValueFreq = sum(packetSampleValues>=aMin);
        %disp(aValueFreq);
        if aValueFreq >= peakPercent * packetLengthOfA
            for i=1:length(packetSampleValues)
                if packetSampleValues(i) < aMin
                    packetSampleValues(i) = aMin + 0.001;
                end
                sampleValues(packetStart:packetEnd) = packetSampleValues;
            end
        else
            for i=1:5
                if packetSampleValues(i) >= aMin
                    packetSampleValues(i) = aMin - 0.1;
                end
                sampleValues(packetStart:packetEnd) = packetSampleValues;
            end
            packetEnd = packetStart;
        
        end
    else
        packetEnd = packetStart;
    end
    %disp([packetStart, packetEnd, packetEnd-packetStart]);

end

function ackPresent = checkForAck(packetEnd, nextFewSamplesForACK, ackMin, ...
    ackMax, sampleValues, peakPercentOfACK)

    packetSamples = sampleValues(packetEnd:packetEnd+nextFewSamplesForACK);
    ackValueFreq = sum(packetSamples>=ackMin & packetSamples<=ackMax);
    %disp(ackValueFreq);
    if ackValueFreq/nextFewSamplesForACK > peakPercentOfACK
        ackPresent = true;
        %disp("true");
    else
        ackPresent = false;
    end

end

% -------------------------------------------------------------------------
