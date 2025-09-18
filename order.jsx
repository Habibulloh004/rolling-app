"use client";

import {
  ClickCheckout,
  createIncomingOrder,
  createOrder,
  createOrderPoster,
  PaymeCheckout,
  updateClient,
} from "@/actions/post";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { formatCreatedAt, formatNumber } from "@/lib/utils";
import { ApiService } from "@/service/api.services";
import { useOrderStore, useProductStore, useStore } from "@/store";
import axios from "axios";
import { ChevronRight, Ticket } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import React, { useEffect, useState } from "react";
import { toast } from "sonner";
import { useTranslations } from "use-intl";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import PromoCodeDialog from "./PromocodeComponent";

const DiscountBadge = ({ auth }) => {
  return (
    <div className="bg-primary rounded-xl w-[150px] h-[100px] flex flex-col justify-between items-center relative py-[5px]">
      <div>
        <p className="font-bold text-white">
          {auth?.client_groups_discount == "10"
            ? "GOLD"
            : auth?.client_groups_discount == "5"
              ? "SILVER"
              : auth?.client_groups_discount == "3"
                ? "BRONZE"
                : "GOLD"}
        </p>
        <p className="font-bold text-center text-white">
          {auth?.client_groups_discount}%
        </p>
      </div>
      <Image
        src={`${auth?.client_groups_discount == "10"
          ? "/assets/Gold.png"
          : auth?.client_groups_discount == "5"
            ? "/assets/Silver.png"
            : auth?.client_groups_discount == "3"
              ? "/assets/Bronze.png"
              : "/assets/Gold.png"
          }`}
        loading="eager"
        alt="gold"
        width={150}
        height={100}
        className="absolute top-0"
      />
      <p className="font-bold text-center text-[6px] text-white">
        ROLLINGSUSHI
      </p>
    </div>
  );
};

// Main Order Component
const Order = ({
  promotions,
  spotDataFilial,
  auth,
  searchParamsData,
  locale,
  place,
  productsData,
  categoriesData,
  apiTime,
}) => {
  const all = useTranslations("All");
  const promocodeT = useTranslations("Order.Promocode");
  const total = useTranslations("Cart.Total");
  const { activeTab, isDisabled, setIsDisabled } = useStore();
  const [isLoading, setIsLoading] = useState(false);
  const [bonus, setBonus] = useState(0);
  const [activeBonus, setActiveBonus] = useState(false);
  const {
    orderData,
    setOrderData,
    totalSum,
    resetOrder,
    paymentData,
    setPaymentData,
    setSelectCard,
  } = useOrderStore();
  const { products, setProductsData } = useProductStore();
  const {
    spot: spotIdSpot,
    table_id,
    table_num,
    service,
    confirm,
  } = searchParamsData;
  const router = useRouter();
  const paymentText = useTranslations("Cart.Payment");
  const [isSuccess, setIsSuccess] = useState(false);
  const defaultTime = { closed_time: "23:00", opened_time: "10:00" };

  const handleSetBonus = () => {
    setOrderData({ ...orderData, pay_bonus: Number(bonus) });
    setBonus(0);
    setActiveBonus(false);
  };
  const handleRemoveBonus = () => {
    setOrderData({ ...orderData, pay_bonus: Number(0) });
    setBonus(0);
    setActiveBonus(false);
  };

  const handleCheckTime = () => {
    console.log({ apiTime });
    let closedTime = defaultTime.closed_time;
    let openedTime = defaultTime.opened_time;

    if (
      apiTime?.opened_time &&
      apiTime?.opened_time !== null &&
      apiTime?.opened_time !== "" &&
      apiTime?.closed_time &&
      apiTime?.closed_time !== null &&
      apiTime?.closed_time !== ""
    ) {
      closedTime = apiTime?.closed_time;
      openedTime = apiTime?.opened_time;
    }

    const [closedHour, closedMinute] = closedTime.split(":").map(Number);
    const [openedHour, openedMinute] = openedTime.split(":").map(Number);

    const currentTime = new Date();
    const hours = currentTime.getHours();
    const minutes = currentTime.getMinutes();
    console.log({ hours, minutes });
    const currentMinutes = hours * 60 + minutes;
    const openedMinutes = openedHour * 60 + openedMinute;
    const closedMinutes = closedHour * 60 + closedMinute;

    let isDisabled;

    if (openedMinutes <= closedMinutes) {
      isDisabled =
        currentMinutes < openedMinutes || currentMinutes >= closedMinutes;
    } else {
      isDisabled =
        currentMinutes < openedMinutes && currentMinutes >= closedMinutes;
    }

    setIsDisabled(isDisabled);
    return isDisabled;
  };

  const handleSubmit = async () => {
    if (handleCheckTime()) {
      return;
    }
    if (products.length == 0) {
      toast.error(all("products_empty"));
      return;
    }
    if (!orderData?.phone && !auth?.client_id) {
      toast.error(all("phone_empty"));
      return;
    }
    if (orderData?.phone && orderData?.phone.length != 13) {
      toast.error(all("phone_empty"));
      return;
    }
    if (!orderData?.phone && spotIdSpot) {
      toast.error(all("phone_empty"));
      return;
    }

    if (activeTab == "pickup" && orderData?.spot_id == 0) {
      toast.error(all("spot_empty"));
      return;
    }

    if (
      activeTab == "delivery" &&
      (!orderData?.lat || orderData?.lat == 0) &&
      (!orderData?.lng || orderData?.lng == 0)
    ) {
      toast.error(all("location_empty"));
      return;
    }
    if (
      orderData?.payment_method == "card" &&
      !paymentData &&
      !paymentData?.payment_id
    ) {
      toast.error(paymentText("you_not_pay"));
      return null;
    }
    if (!orderData?.payment_method || orderData?.payment_method == "") {
      toast.error(paymentText("you_not_select"));
      return null;
    }

    let orderList = localStorage.getItem("orderList")
      ? JSON.parse(localStorage.getItem("orderList"))
      : [];

    try {
      const {
        spot_id,
        spot_name,
        phone,
        payment_method,
        delivery_price,
        lng,
        lat,
        pay_bonus,
        comment,
        address,
        address_comment,
        promocode,
      } = orderData;
      setIsLoading(true);
      const filterProductsAbdugani = products?.map((p) => {
        return {
          product_id: +p.product_id,
          amount: +p.count,
        };
      });
      const filterProductsSpot = products
        ?.filter((pr) => !pr?.promocode)
        ?.map((p) => {
          return {
            product_id: +p.product_id,
            count: +p.count,
          };
        });

      let commentSpot;
      if (!spotIdSpot) {
        commentSpot = comment ? `${comment}, ` : "";
      }
      switch (payment_method) {
        case "card":
          commentSpot = `${commentSpot ?? ""}Тип оплаты : по карте`;
          break;
        case "click":
          commentSpot = `${commentSpot ?? ""}Тип оплаты : через click`;
          break;
        case "payme":
          commentSpot = `${commentSpot ?? ""}Тип оплаты : через payme`;
          break;
        case "uzum":
          commentSpot = `${commentSpot ?? ""}Тип оплаты : через uzum`;
          break;
        default:
          commentSpot = `${commentSpot ?? ""}Тип оплаты : наличными`;
      }
      if (paymentData && paymentData?.transactionId) {
        commentSpot = `${commentSpot}\nТранзакцияID: ${paymentData?.transactionId}`;
      }
      if (promocode) {
        commentSpot = `${commentSpot}\nПромокод:${promocode?.name?.split("$")[1]
          }`;
      }
      if (orderData?.promocodePrice > 0) {
        commentSpot = `${commentSpot}\nПромокодSum: ${orderData?.promocodePrice?.toLocaleString()}`;
      }
      if (orderData?.discountPromocode > 0) {
        commentSpot = `${commentSpot}\nСкидка: ${orderData?.discountPromocode}%`;
      }

      if (spotIdSpot) {
        commentSpot = `${commentSpot ? commentSpot : ""
          }\nНомер стола : ${table_num} \nТип услуги : ${service == "self" ? "самообслуживание" : "официант"
          }\nНомер телефона : ${phone}`;
      } else if (!auth?.client_id) {
        commentSpot = `${commentSpot}\nНомер телефона : ${phone}`;
      }
      commentSpot = `${commentSpot}\nТип заказа: Через веб-сайт`;

      let filterPromocode = null;
      if (promocode && promocode?.params?.result_type == 1) {
        filterPromocode = [
          {
            type: 1,
            id: +promocode?.promotion_id,
            involved_products: promocode?.params?.bonus_products?.map((prd) => {
              return {
                id: +prd?.id,
                count: +promocode?.params?.bonus_products_pcs,
              };
            }),
          },
        ];
      } else {
        console.log({ products })
        const findProductPromotion = products?.filter((pr) => {
          const conditions = orderData?.promocode?.params?.conditions;
          if (conditions[0]?.type == 0 && conditions[0]?.active && promocode?.params?.result_type == 3) {
            return true;
          } else {
            const findPrdCon = conditions?.find(
              (cdp) => cdp?.type == 2 && cdp?.id == pr?.product_id && cdp?.active
            );
            return findPrdCon
          }
        });
        console.log({ findProductPromotion });
        filterPromocode = [
          {
            type: 2,
            id: +promocode?.promotion_id,
            involved_products: findProductPromotion?.map((prd) => {
              return {
                id: +prd?.product_id,
                count: +prd?.count,
              };
            }),
          },
        ];
      }
      console.log(filterPromocode);

      let totalAmount = Number(totalSum * (orderData?.discountPromocode > 0
        ? 1 - orderData?.discountPromocode / 100
        : 1)) - (pay_bonus ? Number(pay_bonus) : 0);

      if (activeTab == "delivery") {
        totalAmount += Number(delivery_price);
      }

      if (orderData?.promocodePrice > 0) {
        totalAmount -= Number(orderData?.promocodePrice);
      }

      if (service == "waiter") {
        totalAmount = Number(totalAmount + (totalAmount * 10) / 100);
      }

      let deliveryData = {
        address_comment,
        all_price: Number((+totalSum + +delivery_price) * 100),
        client_address: `${lat || 0},${lng || 0}`,
        client_id: auth?.client_id ? auth.client_id : "25562",
        comment: commentSpot,
        created_at: formatCreatedAt(),
        payed_bonus: pay_bonus ? Number(pay_bonus) * 100 : 0,
        payed_sum: Number(Math.round(totalAmount)) * 100,
        payment: payment_method == "cash" ? "cash" : "creditCard",
        phone: auth?.client_id ? `+${auth?.phone_number}` : "+998771052018",
        products: JSON.stringify(filterProductsAbdugani),
        promotion: "no",
        spot_id: 0,
        status: "",
        type: "delivery",
        promocode: promocode ? JSON.stringify(filterPromocode) : "",
      };

      let pickupData = {
        address_comment: "no",
        all_price: Number(totalSum * 100),
        client_address: `41.316421,69.247890`,
        client_id: auth?.client_id ? auth?.client_id : "25562",
        comment: commentSpot,
        created_at: formatCreatedAt(),
        payed_bonus: pay_bonus ? Number(pay_bonus) * 100 : 0,
        payed_sum: Number(Math.round(totalAmount)) * 100,
        payment: payment_method == "cash" ? "cash" : "creditCard",
        phone: auth?.client_id ? `+${auth?.phone_number}` : "+998771052018",
        products: JSON.stringify(filterProductsAbdugani),
        promotion: "no",
        spot_id: Number(spot_id),
        status: "",
        type: `take_away ${spot_name}`,
        promocode: promocode ? JSON.stringify(filterPromocode) : "",
      };

      let spotData = {
        phone: spotIdSpot
          ? "+998771244444"
          : auth?.client_id
            ? `+${auth?.phone_number}`
            : "+998771052018",
        products: filterProductsSpot,
        service_mode: spotIdSpot ? 1 : 2,
        spot_id: Number(spotIdSpot ? spotIdSpot : Number(spot_id)),
        comment: commentSpot,
        promotion: promocode ? filterPromocode : null,
      };

      if (address && !spotIdSpot) {
        spotData.address = address;
      }

      console.log({ deliveryData });
      console.log({ pickupData });
      console.log({ spotData });
      console.log(orderData);
      console.log("Spot data", JSON.stringify(spotData));

      let commentClient;
      let clinetGroupId;

      if (auth?.client_id) {
        const commentC = auth?.comment ? JSON.parse(auth?.comment) : null;
        if (Number(commentC?.length) > 0) {
          commentClient = {
            password: commentC?.password,
            length: Number(commentC?.length) + 1,
          };
        } else {
          commentClient = {
            password: commentC?.password,
            length: 1,
          };
        }
        if (commentClient.length < 4) {
          clinetGroupId = 5;
        } else if (commentC.length >= 4 && commentC?.length < 9) {
          clinetGroupId = 3;
        } else if (commentC.length >= 9) {
          clinetGroupId = 4;
        }
      }
      if (payment_method == "payme" || payment_method == "click") {
        if (spotIdSpot) {
          let dataPay = {
            orderDetails: {
              ...spotData,
              service_mode: 1,
              service,
              spot_name: spotDataFilial?.response?.name,
            },
            amount: Math?.round(totalAmount),
            status: payment_method == "payme" ? 0 : 1,
            provider: payment_method,
            url: `https://rolling.uz/${locale}/${place}/cart?spot=${spotIdSpot}&table_id=${table_id}&table_num=${table_num}&service=${service}&confirm=true`,
          };
          if (auth?.client_id) {
            dataPay.userId = auth?.client_id;
          }
          let res;
          switch (payment_method) {
            case "payme":
              res = await PaymeCheckout(dataPay);
              break;
            case "click":
              res = await ClickCheckout(dataPay);
              break;
          }
          console.log({ res });
          if (res) {
            window.open(res.url, "_blank");
            // const nowOrder = {
            //   ...deliveryData,
            //   response: res,
            // };
            // orderList.push(nowOrder);
            // localStorage.setItem("orderList", JSON.stringify(orderList));
            setPaymentData(null);
            setOrderData({
              spot_id: 0,
              spot_name: "",
              phone: "",
              products: [],
              payment_method: "",
              total: 0,
              lng: 0,
              lat: 0,
              delivery_price: 10000,
              client: null,
              pay_cash: null,
              pay_card: null,
              pay_click: null,
              pay_payme: null,
              pay_uzum: null,
              pay_bonus: null,
              promocode: null,
              comment: "",
              address: "",
              client_addresses_id: null,
            });
            setSelectCard(null);
            setProductsData([]);
            window.dataLayer?.push({
              event: "purchase",
              ecommerce: {
                transaction_id: Math.floor(100000 + Math.random() * 900000),
                value: totalAmount, // umumiy narx
                currency: "UZS", // valyuta
                items: spotData?.products,
              },
            });
          }
        } else {
          if (activeTab == "pickup") {
            let dataPay = {
              orderDetails: {
                ...pickupData,
                service_mode: 3,
              },
              amount: Math?.round(totalAmount),
              status: payment_method == "payme" ? 0 : 1,
              provider: payment_method,
              url: `https://rolling.uz/${locale}/${place}/confirmedpay`,
            };
            if (auth?.client_id) {
              dataPay.userId = auth?.client_id;
            }
            let res;
            switch (payment_method) {
              case "payme":
                res = await PaymeCheckout(dataPay);
                break;
              case "click":
                res = await ClickCheckout(dataPay);
                break;
            }
            console.log({ res });
            if (res) {
              router.push(res.url);
              // router.push(`/${locale}/${place}/confirmedpay/${res?.order_id}`);
              const nowOrder = {
                ...pickupData,
                order_id: res.order_id,
                payment_type: payment_method,
              };
              orderList.push(nowOrder);
              localStorage.setItem("orderList", JSON.stringify(orderList));
              setOrderData({
                spot_id: 0,
                spot_name: "",
                delivery_price: 10000,
                phone: "",
                products: [],
                payment_method: "",
                total: 0,
                lng: 0,
                lat: 0,
                client: null,
                pay_cash: null,
                pay_card: null,
                pay_click: null,
                pay_payme: null,
                pay_uzum: null,
                pay_bonus: null,
                comment: "",
                address: "",
                promocode: null,
                client_addresses_id: null,
              });
              setSelectCard(null);
              setPaymentData(null);
              setProductsData([]);
              window.dataLayer?.push({
                event: "purchase",
                ecommerce: {
                  transaction_id: Math.floor(100000 + Math.random() * 900000),
                  value: totalAmount, // umumiy narx
                  currency: "UZS", // valyuta
                  items: spotData?.products,
                },
              });
              if (auth?.client_id) {
                await updateClient({
                  client_id: auth?.client_id,
                  comment: JSON.stringify(commentClient),
                  client_groups_id_client: clinetGroupId,
                });
              }
              toast.success(all("order_created"));
            }
          } else if (activeTab == "delivery") {
            let dataPay = {
              orderDetails: { ...deliveryData, service_mode: 2 },
              amount: Math?.round(totalAmount),
              status: payment_method == "payme" ? 0 : 1,
              provider: payment_method,
              url: `https://rolling.uz/${locale}/${place}/confirmedpay`,
            };
            if (auth?.client_id) {
              dataPay.userId = auth?.client_id;
            }
            let res;
            switch (payment_method) {
              case "payme":
                res = await PaymeCheckout(dataPay);
                break;
              case "click":
                res = await ClickCheckout(dataPay);
                break;
            }
            console.log({ res });
            console.log("dataPay", JSON.stringify(dataPay));

            if (res) {
              router.push(res.url);
              // router.push(`/${locale}/${place}/confirmedpay/${res?.order_id}`);
              setOrderData({
                spot_id: 0,
                delivery_price: 10000,
                spot_name: "",
                phone: "",
                products: [],
                payment_method: "",
                total: 0,
                lng: 0,
                lat: 0,
                client: null,
                pay_cash: null,
                pay_card: null,
                pay_click: null,
                pay_payme: null,
                pay_uzum: null,
                pay_bonus: null,
                comment: "",
                address: "",
                promocode: null,
                client_addresses_id: null,
              });
              const nowOrder = {
                ...deliveryData,
                order_id: res?.order_id,
                payment_type: payment_method,
              };
              setPaymentData(null);
              orderList.push(nowOrder);
              localStorage.setItem("orderList", JSON.stringify(orderList));
              setProductsData([]);
              setSelectCard(null);
              toast.success(all("order_created"));
              window.dataLayer?.push({
                event: "purchase",
                ecommerce: {
                  transaction_id: Math.floor(100000 + Math.random() * 900000),
                  value: totalAmount, // umumiy narx
                  currency: "UZS", // valyuta
                  items: spotData?.products,
                },
              });
              if (auth?.client_id) {
                await updateClient({
                  client_id: auth?.client_id,
                  comment: JSON.stringify(commentClient),
                  client_groups_id_client: clinetGroupId,
                });
              }
            }
          }
        }
      } else {
        if (spotIdSpot) {
          const res = await createIncomingOrder(spotData);
          console.log(res);

          if (res?.response) {
            const { transaction_id } = res?.response;

            const nowOrder = {
              ...deliveryData,
              response: res,
            };
            const message = `
📦 Новый заказ! №${transaction_id}
🛒 Название филиал: ${spotDataFilial?.response?.name}
📞 Телефон: +998771244444
💵 Сумма заказа: ${formatNumber(
              service == "waiter"
                ? Number(totalSum + (totalSum * 10) / 100)
                : Number(totalSum)
            )} сум
💳 Метод оплаты: ${orderData?.payment_method == "cash"
                ? "Наличные"
                : "Карта (Оплачено)"
              }
🛍 Тип заказа: Заведения
✏️ Комментарий: ${commentSpot}`.trim();

            await axios.get(
              `https://api.telegram.org/bot7051935328:AAFJxJAVsRTPxgj3rrHWty1pEUlMkBgg9_o/sendMessage?chat_id=-1002211902296&text=${encodeURIComponent(
                message
              )}`
            );

            orderList.push(nowOrder);
            localStorage.setItem("orderList", JSON.stringify(orderList));
            setPaymentData(null);
            setOrderData({
              spot_id: 0,
              spot_name: "",
              phone: "",
              products: [],
              payment_method: "",
              total: 0,
              lng: 0,
              lat: 0,
              delivery_price: 10000,
              client: null,
              pay_cash: null,
              pay_card: null,
              pay_click: null,
              pay_payme: null,
              pay_uzum: null,
              pay_bonus: null,
              promocode: null,
              comment: "",
              address: "",
              client_addresses_id: null,
            });
            setSelectCard(null);
            setProductsData([]);
            toast.success(all("order_created"));
            setIsSuccess(true);
            window.dataLayer?.push({
              event: "purchase",
              ecommerce: {
                transaction_id: transaction_id,
                value: totalAmount, // umumiy narx
                currency: "UZS", // valyuta
                items: spotData?.products,
              },
            });
          }
        } else {
          if (activeTab == "pickup") {
            const res = await createOrder(pickupData);
            console.log({ res });
            if (res?.order_id) {
              const nowOrder = {
                ...pickupData,
                order_id: res.order_id,
                payment_type: payment_method,
              };
              orderList.push(nowOrder);
              localStorage.setItem("orderList", JSON.stringify(orderList));
              setOrderData({
                spot_id: 0,
                spot_name: "",
                delivery_price: 10000,
                phone: "",
                products: [],
                payment_method: "",
                total: 0,
                lng: 0,
                lat: 0,
                client: null,
                pay_cash: null,
                pay_card: null,
                pay_click: null,
                pay_payme: null,
                pay_uzum: null,
                pay_bonus: null,
                comment: "",
                address: "",
                promocode: null,
                client_addresses_id: null,
              });
              setSelectCard(null);
              setPaymentData(null);
              setProductsData([]);
              if (auth?.client_id) {
                await updateClient({
                  client_id: auth?.client_id,
                  comment: JSON.stringify(commentClient),
                  client_groups_id_client: clinetGroupId,
                });
              }
              window.dataLayer?.push({
                event: "purchase",
                ecommerce: {
                  transaction_id: res?.order_id,
                  value: totalAmount, // umumiy narx
                  currency: "UZS", // valyuta
                  items: spotData?.products,
                },
              });
              toast.success(all("order_created"));
              router.push(`/${locale}/${place}/confirmed/${res?.order_id}`);
            }
          } else if (activeTab == "delivery") {
            const res = await createOrder(deliveryData);
            if (res?.order_id) {
              setOrderData({
                spot_id: 0,
                delivery_price: 10000,
                spot_name: "",
                phone: "",
                products: [],
                payment_method: "",
                total: 0,
                lng: 0,
                lat: 0,
                client: null,
                pay_cash: null,
                pay_card: null,
                pay_click: null,
                pay_payme: null,
                pay_uzum: null,
                pay_bonus: null,
                comment: "",
                address: "",
                promocode: null,
                client_addresses_id: null,
              });
              const nowOrder = {
                ...deliveryData,
                order_id: res.order_id,
                payment_type: payment_method,
              };
              setPaymentData(null);
              orderList.push(nowOrder);
              localStorage.setItem("orderList", JSON.stringify(orderList));
              setProductsData([]);
              setSelectCard(null);
              toast.success(all("order_created"));
              router.push(`/${locale}/${place}/confirmed/${res?.order_id}`);
              window.dataLayer?.push({
                event: "purchase",
                ecommerce: {
                  transaction_id: res?.order_id,
                  value: totalAmount, // umumiy narx
                  currency: "UZS", // valyuta
                  items: spotData?.products,
                },
              });
              if (auth?.client_id) {
                await updateClient({
                  client_id: auth?.client_id,
                  comment: JSON.stringify(commentClient),
                  client_groups_id_client: clinetGroupId,
                });
              }
            }
          }
        }
      }
    } catch (error) {
      console.log(error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleRederect = () => {
    setIsSuccess(false);
    router.push(
      `/${locale}/${place}?spot=${spotIdSpot}&table_id=${table_id}&table_num=${table_num}&service=${service}`
    );
  };

  useEffect(() => {
    if (paymentData && paymentData?.success && paymentData?.transactionId) {
      handleSubmit();
    }
  }, [paymentData?.success]);

  useEffect(() => {
    if (orderData?.pay_bonus > totalSum) {
      handleRemoveBonus();
    }
  }, [totalSum]);

  useEffect(() => {
    if (confirm) {
      toast.success(all("order_created"));
      setIsSuccess(true);
    }
  }, []);

  console.log(orderData);

  return (
    <div className="w-full flex flex-col lg:pt-6 gap-5">
      <div className="max-lg:hidden flex flex-col gap-y-4">
        <div className="w-full flex justify-between">
          <p className="font-medium textSmall3 leading-5 text-[#2E2E2E] text-start md:text-end">
            {service == "self" ? total("total") : total("products_sum")}{" "}
          </p>
          <p className="font-normal textNormal2 leading-7 text-[#2E2E2E]">
            {formatNumber(totalSum)} {all("sum")}
          </p>
        </div>
        {orderData?.promocodePrice > 0 && (
          <div className="w-full flex justify-between">
            <p className="font-medium textSmall3 leading-5 text-[#2E2E2E] text-start md:text-end">
              {promocodeT("titleDialog")}
            </p>
            <p className="text-primary font-normal textNormal2 leading-7 text-[#2E2E2E]">
              -{formatNumber(orderData?.promocodePrice)} {all("sum")}
            </p>
          </div>
        )}
        {orderData?.discountPromocode > 0 && (
          <div className="w-full flex justify-between">
            <p className="font-medium textSmall3 leading-5 text-[#2E2E2E] text-start md:text-end">
              {promocodeT("titleDialog")}
            </p>
            <p className="text-primary font-normal textNormal2 leading-7 text-[#2E2E2E]">
              {formatNumber(orderData?.discountPromocode)}% {all("disc")}
            </p>
          </div>
        )}
        {activeTab === "delivery" && (
          <div className="w-full flex justify-between">
            <p className="font-medium textSmall3 leading-5 text-[#2E2E2E] text-start md:text-end">
              {total("delivery")}
            </p>
            <p className="font-normal textNormal2 leading-7 text-[#2E2E2E]">
              {formatNumber(orderData?.delivery_price)} {all("sum")}
            </p>
          </div>
        )}
        {activeTab !== "spot" && (
          <div className="w-full flex justify-between">
            <p className="font-medium textSmall3 leading-5 text-[#2E2E2E] text-start md:text-end">
              {total("bonus")}
            </p>
            <p className="font-normal textNormal2 leading-7 text-[#2E2E2E]">
              {formatNumber(Number(orderData?.pay_bonus))} {all("sum")}
            </p>
          </div>
        )}
        {activeTab !== "spot" && (
          <div className="w-full flex justify-between">
            <p className="font-medium textSmall3 leading-5 text-[#2E2E2E] text-start md:text-end">
              {total("total")}
            </p>
            <p className="font-normal textNormal3 leading-7 text-[#2E2E2E]">
              {formatNumber(
                (Number(totalSum *
                  (orderData?.discountPromocode > 0
                    ? 1 - orderData?.discountPromocode / 100
                    : 1)) -
                  Number(orderData?.pay_bonus) +
                  (activeTab == "delivery" ? orderData?.delivery_price : 0) -
                  (orderData?.promocodePrice > 0 &&
                    Number(orderData?.promocodePrice)))
              )}{" "}
              {all("sum")}
            </p>
          </div>
        )}
        {activeTab == "spot" && service == "waiter" && (
          <div className="w-full flex justify-between">
            <p className="font-medium textSmall3 leading-5 text-[#2E2E2E] text-start md:text-end">
              {all("waiter")}
            </p>
            <p className="font-normal textNormal2 leading-7 text-[#2E2E2E]">
              10%
            </p>
          </div>
        )}
        {activeTab == "spot" && service == "waiter" && (
          <div className="w-full flex justify-between">
            <p className="font-medium textSmall3 leading-5 text-[#2E2E2E] text-start md:text-end">
              {total("total")}
            </p>
            <p className="font-normal textNormal3 leading-7 text-[#2E2E2E]">
              {formatNumber(Number(totalSum + (totalSum * 10) / 100))}
              {all("sum")}
            </p>
          </div>
        )}
      </div>
      <div className="space-y-2 md:space-y-4">
        <PromoCodeDialog
          locale={locale}
          categoriesData={categoriesData}
          auth={auth}
          promotions={promotions?.response}
          productsData={productsData}
        />
        {activeTab !== "spot" && (
          <>
            <Button
              aria-label={`sign in`}
              disabled={paymentData && paymentData?.payment_id}
              onClick={() => {
                if (auth?.client_id) {
                  setActiveBonus(true);
                } else {
                  toast.error(
                    <div className="w-full h-full flex justify-start items-center">
                      <h1 className="w-full">{all("no_auth")} </h1>
                      <Link
                        href={`/${locale}/${place}/login`}
                        className="min-w-[80px] flex justify-center items-center h-full bg-black text-white rounded-md px-3 py-2"
                      >
                        {all("sign_in")}
                      </Link>
                    </div>
                  );
                }
              }}
              className="bg-[#F5F5F5] w-full h-10 md:h-12 flex justify-center items-center gap-1 border-[1px] rounded-xl"
            >
              <Image
                src={"/assets/gift.webp"}
                alt="gift"
                width={100}
                height={100}
                className="w-7 md:w-9 h-7 md:h-8"
              />
              <p className="font-medium text-sm sm:text-md leading-5 text-[#2E2E2E]">
                {total("bonus_pay")}
              </p>
              <p className="text-[#2E2E2E]">
                <ChevronRight />
              </p>
            </Button>
            {activeBonus && auth?.client_id && (
              <div className="flex-col w-full p-5 border-[1px] shadow-md rounded-xl mt-3">
                <div className="w-full flex justify-between gap-2">
                  <div className="flex flex-col items-center gap-4">
                    <p className="text-[#373737] textNormal2">
                      {total("have_bonus")}
                    </p>
                    <p className="textSmall5">
                      {formatNumber(Number(auth.bonus / 100))} {all("sum")}
                    </p>
                  </div>
                  <DiscountBadge auth={auth} />
                </div>
                <div className="mt-[7px]">
                  <p className="text-[#373737] pb-1 font-medium">
                    {all("choose")} {all("sum")}
                  </p>
                  <Input
                    onChange={(e) => {
                      let value = e.target.value;

                      value = value.replace(/[^0-9]/g, "");

                      const maxBonus = Math.min(auth?.bonus / 100, totalSum);
                      value = Math.min(Number(value), maxBonus);

                      setBonus(value);
                    }}
                    value={formatNumber(Number(bonus))}
                    type="text"
                    placeholder={`45 000 ${all("sum")}`}
                    className="outline-none border-[2px] bg-transparent p-2 md:p-3 focus-visible:ring-0 focus:border-primary w-full text-[12px] md:text-sm rounded-md"
                  />
                </div>
                <div className="w-full flex justify-around items-center pt-7 gap-2 textSmall2">
                  <Button
                    aria-label={`confirm`}
                    onClick={handleSetBonus}
                    className="w-full hover:bg-primary md:py-2 md:h-12"
                  >
                    {all("confirm")}
                  </Button>
                  <Button
                    aria-label={`cancel`}
                    onClick={() => setActiveBonus(false)}
                    className="w-full border text-[#004032] shadow-none bg-transparent hover:bg-transparent md:py-2 md:h-12"
                  >
                    {all("cancel")}
                  </Button>
                </div>
              </div>
            )}
          </>
        )}
        {orderData?.payment_method != "card" && (
          <Button
            aria-label={`loading`}
            disabled={isLoading || isDisabled}
            // disabled={isLoading}
            onClick={handleSubmit}
            className="mb-3 w-full h-12 flex justify-center items-center gap-1 border-[1px] rounded-xl hover:bg-primary md:mt-5 font-medium text-sm md:text-md"
          >
            {isLoading ? (
              <div>
                <div className="flex items-center gap-4">
                  <div role="status">
                    <svg
                      aria-hidden="true"
                      className="w-6 h-6 text-gray-300 animate-spin dark:text-gray-600 fill-gray-700"
                      viewBox="0 0 100 101"
                      fill="none"
                      xmlns="http://www.w3.org/2000/svg"
                    >
                      <path
                        d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
                        fill="currentColor"
                      />
                      <path
                        d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
                        fill="currentFill"
                      />
                    </svg>
                    <span className="text-black sr-only">{all("loading")}</span>
                  </div>
                  {all("loading")}
                </div>
              </div>
            ) : (
              <div>{total("submit")}</div>
            )}
          </Button>
        )}
        {isDisabled && (
          <div className="w-full p-5 border-[1px] border-[#979797] rounded-xl mt-3">
            <p
              className="font-medium"
              dangerouslySetInnerHTML={{ __html: total("note") }}
            />
          </div>
        )}
      </div>
      <AlertDialog open={isSuccess}>
        <AlertDialogTrigger className="hidden">Open</AlertDialogTrigger>
        <AlertDialogContent className="w-11/12 mx-auto rounded-md">
          <AlertDialogHeader>
            <AlertDialogTitle>{all("order_created")}</AlertDialogTitle>
            <AlertDialogDescription>
              {all("additional_info")}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogAction onClick={handleRederect}>OK</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
};

export default Order;
