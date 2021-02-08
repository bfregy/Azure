# culture="en-US"
ConvertFrom-StringData @'
    RetrievingADUserError                = Error retrieving '{0}' from domain '{1}'. (ADU0001)
    PasswordParameterConflictError       = Parameter '{0}' cannot be set to '{1}' when the '{2}' parameter is specified. (ADU0002)
    ChangePasswordParameterConflictError = Parameter 'ChangePasswordAtLogon' cannot be set to 'true' when Parameter 'PasswordNeverExpires' is also set to 'true'. (ADU0003)
    RetrievingADUser                     = Retrieving '{0}' from domain '{1}'. (ADU0004)
    ADUserIsPresent                      = '{0}' is present in domain '{1}'. (ADU0007)
    ADUserNotPresent                     = '{0}' is not present in domain '{1}'. (ADU0008)
    ADUserInDesiredState                 = '{0}' is in the desired state. (ADU0009)
    ADUserNotInDesiredState              = '{0}' is not in the desired state. (ADU0010)
    ADUserIsPresentButShouldBeAbsent     = '{0}' is present but should be absent. (ADU0011)
    ADUserIsAbsentButShouldBePresent     = '{0}' is absent but should be present. (ADU0012)
    ADUserNotDesiredPropertyState        = '{0}' property is NOT in the desired state. Expected '{1}', actual '{2}'. (ADU0013)
    AddingADUser                         = Adding '{0} to domain '{1}'. (ADU0014)
    RemovingADUser                       = Removing '{0}' from domain '{1}'. (ADU0015)
    UpdatingADUser                       = Updating '{0}' in domain '{1}'. (ADU0016)
    SettingADUserPassword                = Setting password for '{0}'. (ADU0017)
    UpdatingADUserProperty               = Updating property '{0}' with '{1}'. (ADU0018)
    ClearingADUserProperty               = Clearing property '{0}'. (ADU0019)
    MovingADUser                         = Moving user from '{0}' to '{1}'. (ADU0020)
    RestoringUser                        = Attempting to restore the user object {0} from the recycle bin. (ADU0022)
    LoadingThumbnailFromFile             = Importing thumbnail photo from the file '{0}'. (ADU0024)
    ThumbnailPhotoNotAFile               = Expected the thumbnail photo to be a file because the string contained the character '.' or '\', but the file could not be found. (ADU0025)
    UpdatingThumbnailPhotoProperty       = Updating property '{0}' with a new thumbnail photo with MD5 hash '{1}'. (ADU0026)
'@
