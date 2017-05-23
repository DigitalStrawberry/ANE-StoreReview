/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2017 Digital Strawberry LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

package com.digitalstrawberry.ane.storereview
{

	CONFIG::ane
	{
		import flash.external.ExtensionContext;
	}

	import flash.system.Capabilities;

	public class StoreReview
	{
		/**
		 * Extension version.
		 */
		public static const VERSION:String = "1.0.0";

		private static const TAG:String = "[StoreReview]";
		private static const EXTENSION_ID:String = "com.digitalstrawberry.ane.storeReview";
		private static const iOS:Boolean = Capabilities.manufacturer.indexOf("iOS") > -1;

		CONFIG::ane
		{
			private static var mContext:ExtensionContext;
		}


		/**
		 * @private
		 * Do not use. StoreReview is a static class.
		 */
		public function StoreReview()
		{
			throw Error("StoreReview is static class.");
		}


		/**
		 *
		 *
		 * Public API
		 *
		 *
		 */

		/**
		 * Tells StoreKit to ask the user to rate or review your app, if appropriate.
		 *
		 * <p>
		 * Although you should call this method when it makes sense in the user experience flow of your app,
		 * the actual display of a rating/review request view is governed by App Store policy.
		 * Because this method may or may not present an alert, it's not appropriate to call it in response
		 * to a button tap or other user action.
		 * </p>
		 *
		 * <p>
		 * When you call this method while your app is still in development mode, a rating/review request view
		 * is always displayed so that you can test the user interface and experience. However, this method has
		 * no effect when you call it in an app that you distribute using TestFlight.
		 * </p>
		 */
		public static function requestReview():void
		{
			if(!isSupported)
			{
				return;
			}

			CONFIG::ane
			{
				mContext.call("requestReview");
			}
		}


		/**
		 * Disposes native extension context.
		 */
		public static function dispose():void
		{
			if(!isSupported)
			{
				return;
			}

			CONFIG::ane
			{
				mContext.dispose();
				mContext = null;
			}
		}


		/**
		 *
		 *
		 * Getters / Setters
		 *
		 *
		 */


		/**
		 * The extension tracks the number of requests made in the last 365 days and the current app environment
		 * (development, TestFlight, App Store) to determine whether the review dialog will display or not.
		 *
		 * <p>
		 * If less than 3 requests have been made in the last 365 days, this method returns true.
		 * It always returns true during development (when deploying app directly to a device).
		 * TestFlight builds always return false.
		 * </p>
		 *
		 * <p>
		 * Note the user may have already left a review or disabled the rating prompts for all apps
		 * in the device settings. This information is not available, thus the returned value may not
		 * be correct in all situations.
		 * </p>
		 */
		public static function get willDialogDisplay():Boolean
		{
			if(!isSupported)
			{
				return false;
			}

			var result:Boolean = false;
			CONFIG::ane
			{
				result = mContext.call("willDialogDisplay") as Boolean;
			}
			return result;
		}
		

		/**
		 * Returns the number of days since the last request,
		 * or -1 if no requests have been made.
		 */
		public static function get daysSinceLastRequest():int
		{
			if(!isSupported)
			{
				return -1;
			}

			var result:int = -1;
			CONFIG::ane
			{
				result = mContext.call("daysSinceLastRequest") as int;
			}
			return result;
		}


		/**
		 * Returns the number of requests made in the last 365 days.
		 */
		public static function get numRequestsIn365Days():int
		{
			if(!isSupported)
			{
				return 0;
			}

			var result:int = 0;
			CONFIG::ane
			{
				result = mContext.call("reviewRequestsIn365Days") as int;
			}
			return result;
		}


		/**
		 * Supported on iOS 10.3+.
		 */
		public static function get isSupported():Boolean
		{
			if(!iOS || !initExtensionContext())
			{
				return false;
			}

			var result:Boolean = false;
			CONFIG::ane
			{
				result = mContext.call("isSupported") as Boolean;
			}
			return result;
		}


		/**
		 *
		 *
		 * Private API
		 *
		 *
		 */

		/**
		 * Initializes extension context.
		 * @return true if initialized successfully, false otherwise.
		 */
		private static function initExtensionContext():Boolean
		{
			CONFIG::ane
			{
				try
				{
					if(mContext == null)
					{
						mContext = ExtensionContext.createExtensionContext(EXTENSION_ID, null);
					}
					return mContext != null;
				}
				catch(error:Error)
				{
					trace(TAG, error);
				}
			}
			return false;
		}

	}
}
