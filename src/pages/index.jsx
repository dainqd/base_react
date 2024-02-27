import { IconButton } from '@material-ui/core'
import React, { useState } from 'react'
import Conference from './Conference'
import VideocamIcon from '@material-ui/icons/Videocam';

const Home = () => {
    const [activeWindow, setActiveWindow] = useState("chat");

    return (
        <>
            <div id="Home">
                <div className="chat_cont">
                    <div className="header font-weight-bold text-center d-flex align-items-center justify-content-center text-white">
                        Main Header
                    </div>
                    <div className="col-12 d-flex m-0 p-0">
                        <div id="user_list">
                            Sidebar | Userslist
                        </div>
                        <div id="chat_window">
                            <div className="chat_header font-weight-bold text-center d-flex align-items-center justify-content-center">
                                Chat Header
                                <IconButton onClick={()=>setActiveWindow('call')} className="videocall_icon">
                                    <VideocamIcon style={{color: "#fff"}} />
                                </IconButton>
                            </div>
                            {activeWindow === 'call' ? (
                                <Conference setActiveWindow={setActiveWindow} ></Conference>

                            ) : (
                                <div className="text_chat_wrapper">
                                    text chat window
                                </div>
                            )}
                            <div className="chat_input_container">

                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <style jsx="true">{`
            #user_list{
                width: 30%;
                background: whitesmoke;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            #chat_window{
                width: -webkit-fill-available;
                // min-width: 800px;
            }
            .chat_cont{
                height: 100vh;
            }
            .header {
                height: 70px;
                width: 100%;
                background: deeppink;
            }
            .chat_header{
                height: 60px;
                background: whitesmoke;
            }
            .chat_input_container{
                height: 40px;
                background: whitesmoke;
            }
            .videocall_icon{
                position: absolute;
                right: 10px;
                background: #4aab4d !important;
            }
            .text_chat_wrapper{
                height: calc(100vh - (70px + 40px + 60px));
                width: 100%;
                justify-content: center;
                overflow: auto;
            }
            @media only screen and (max-width: 700px){
                #user_list{
                    display: none;
                }
            }
        `}</style>
        </>
    )
}

export default Home
