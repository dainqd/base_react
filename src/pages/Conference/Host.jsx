import React, { useEffect } from 'react'
import MediaPlayer from '../../components/MediaPlayer';
import useAgora from '../../hooks/useAgora'
import { APP_ID, TOKEN } from '../../lib/config';
import queryString from 'query-string';

const Host = (props) => {
    const query = queryString.parse(window?.location?.search)
    const {client,localAudioTrack, localVideoTrack} = props;
    const token = query?.token || TOKEN;
    // const {
    //     localAudioTrack,
    //     localVideoTrack,
    //     join,
    //     joinState,
    //     leave
    // } = useAgora(client);

    // useEffect(()=>{
    //     handleClickHost()
    // },[]);


    // const handleClickHost = async() => {
    //     join(APP_ID, "Fanzly", token).then(res=>{
    //         console.log(res)
    //     })
    // }
    return (
        <React.Fragment>

            <div className="local_vide_cont h-100">
                <MediaPlayer
                    audoTrack={localAudioTrack}
                    videoTrack={localVideoTrack}
                    avatarSize="50px"
                ></MediaPlayer>
            </div>
            <style>{`
                .local_vide_cont{
                    background: black;
                    border-radius: 8px;
                }
            `}</style>
        </React.Fragment>
    )
}

export default Host
