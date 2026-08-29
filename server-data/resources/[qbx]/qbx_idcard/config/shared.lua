return {

    idCardSettings = {
        closeKey = 'Backspace',
        autoClose = {
            status = true, -- was false: the card never had another way to close for players who don't know the Backspace close key
            time = 8000
        }
    },

    licenses = {
        ['id_card'] = {
            header = 'Identity',
            background = '#ebf7fd',
            backgroundImage = 'https://i.ibb.co/vxvGzg1/card.png',
            prop = 'prop_franklin_dl'
        },
        ['driver_license'] = {
            header = 'Driver License',
            background = '#febbbb',
            backgroundImage = 'https://i.ibb.co/vxvGzg1/card.png',
            prop = 'prop_franklin_dl',
        },
        ['weaponlicense'] = {
            header = 'Weapon License',
            background = '#c7ffe5',
            backgroundImage = 'https://i.ibb.co/vxvGzg1/card.png',
            prop = 'prop_franklin_dl',
        },
        ['lawyerpass'] = {
            header = 'Lawyer Pass',
            background = '#f9c491',
            backgroundImage = 'https://i.ibb.co/vxvGzg1/card.png',
            prop = 'prop_cs_r_business_card'
        }
    }
}
