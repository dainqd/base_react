import React, { useEffect } from 'react'
import Avatar from '@material-ui/core/Avatar';
import PersonIcon from '@material-ui/icons/Person';
/**
 * @description use thic component for Media playing
 * @author jagannath
 * @date 22/04/2021
 * @param videoTrack:any
 * @param audioTrack:any
 * @param avatarHeight: String
 * @param avatarWidth: String
 * @param avatarSize: String
 * @param avatarClass: ?String
 */
const MediaPlayer = (props) => {
    const {videoTrack, audioTrack} = props;
    const container = React.useRef(null);

    useEffect(() => {
        if(!container.current) return;

        videoTrack?.play?.(container?.current)
        return () => {
            videoTrack?.stop?.()
        }
    }, [container, videoTrack])

    useEffect(()=>{
        audioTrack?.play?.();
        return ()=>{
            audioTrack?.stop?.()
        }
    },[audioTrack])


    return (
        <React.Fragment>
            <div ref={container} className="video-player h-100 d-flex">
                {!videoTrack ? (
                    <Avatar className={`profile_avatar ${props.avatarClass}`}>
                        <PersonIcon
                            style={{
                                fontSize: props.avatarSize || '100px'
                            }}
                            className="avatar_icon"></PersonIcon>
                    </Avatar>
                ) : <></>}
            </div>
            <style>{`
                .profile_avatar{
                    height: ${props.avatarHeight || '60%'};
                    width: ${props.avatarWidth || '60%'};
                    margin: auto;
                    max-width: 200px;
                    max-height: 200px;
                }
                .avatar_icon{
                    color: #fff;
                }
            `}</style>
        </React.Fragment>
    )
}

export default MediaPlayer
