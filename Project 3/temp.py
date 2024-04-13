def transmission(df,ack):
    good=[]
    bad=[]
    temp_frame=-1

    exp_ACK=0
    timer_up = 0
    r_bad=[]
    timer_down = 0
    success=1
    time_out = []
    left = 0
    right = 6
    frame = 0
    trans_ACK = 1
    received_ACK=[]
    ra=0
    received_frame=[]
    rf=0
    temp=0
    ack_count=0
    r_receive=0
    r_sent=[]
    r_timer=[]
    f=0
    i=0
    count=0
    act_frame=0
    timeout=0
    #C0de for transmission
    for j in range(len(df)):

        # Calling receiver function
         if good!=[] and r_timer!=[]:
          if timer_up==116:
              print("heko")
          if timer_up - r_timer[r_receive] == 4:

             # if received_frame in bad:
             #    received_frame=good[r_receive]
             #    timer_down+=1
             #
             #    continue
             rf = good[r_receive]
             received_frame.append(rf)
             trans_ACK, ack_count,r_bad,received_ACK = receiver(timer_up, ack, rf, trans_ACK, good, ack_count,r_bad,received_ACK)
             r_receive += 1
            # timer_down += 1
             if timer_up not in r_bad:
              r_sent.append(timer_up)
              f-=1

             # COde for sender function
         if r_sent != []:



                 if r_sent[f]+3 == timer_up and r_sent[f] not in r_bad:
                     ra=received_ACK[f]


                     left = ra
                     right = ra+6
                     f += 1
                     sender(timer_up, ra, left, right)

         if time_out!=[]:
            if timer_up==time_out[0]:
             time_out.pop(0)
             timer_up+=1
             continue

         if df[i] == 1:

                    if success  :
                     print("time {}: sender window [{},{}], transmitting new frame {} good transmission".format(timer_up, left, right, frame))
                     good.append(frame)

                    else:
                      print("time {}: sender window [{},{}], re-transmitting old frame {} good transmission".format(timer_up, left,right, temp_frame))

                      good.append(temp_frame)
                     # if temp_frame in bad:
                     #     success=timer_up
                     #temp_frame += 1
                    r_timer.append(timer_up)
                #  frame+=1
         if df[i] == 0 :
                    if success==1:
                     print("time {}: sender window [{},{}], transmitting new frame {} bad transmission".format(timer_up, left, right, frame))
                     bad.append(frame)
                    else:

                     print("time {}: sender window [{},{}], re-transmitting old frame {} bad transmission".format(timer_up, left,right, temp_frame))
                     bad.append(temp_frame)


                    #temp_frame += 1
                    timeout = timer_up + 7
                    time_out.append(timeout)
                    #temp_frame+=1
                    temp=frame
         i+=1
         timer_up += 1
         if right==frame and left not in good:
             frame+=1
             success=0
         if success==1:
             frame+=1
         if success==0:
            if left not in good:
             if temp_frame==right:
                 count=0
             if count==0:
              act_frame = frame + 1
              temp_frame = bad[0]
              bad.pop(0)
              count=1
              continue

            if left in good:
              #temp_frame+=1
              if temp_frame==right:
                success=1
            temp_frame += 1
def receiver(timer_up,ack,rf, trans_ACK,good,ack_count,r_bad,received_ACK):
    i=ack_count
    if rf==trans_ACK:
        trans_ACK += 1
    if ack[i]==1:
     print("time {}: receiver got frame {}, transmitting ACK{}, good transmission".format(timer_up,rf,trans_ACK))
     received_ACK.append(trans_ACK)
     #trans_ACK += 1
    if ack[i]==0:
     print("time {}: receiver got frame {}, transmitting ACK{}, bad transmission".format(timer_up,rf,trans_ACK))
     r_bad.append(timer_up)
#for transmitting new ACK

    ack_count+=1
    return trans_ACK,ack_count,r_bad,received_ACK


def sender(timer_up, ra, left, right):
    print("time {}: Sender got ACK {}, window[{},{}]".format(timer_up, ra, left, right))

import numpy as np
Data_Frame=open(r"DATA_GOOD","r")
df=np.loadtxt(Data_Frame,dtype="int")
#df=df.values.tolist()
Ack_data=open(r"ACK_GOOD","r")
ack=np.loadtxt(Ack_data,dtype="int")
#ack=ack.values.tolist()

timer_up=0
received_ACK=0
left=0
right=6


#Calling the sender function
sender(timer_up,received_ACK,left,right)
#Calling the transmission function
transmission(df,ack)